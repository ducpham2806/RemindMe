import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:remindme_core/remindme_core.dart';

import 'database.dart';
import 'items_repository.dart';
import 'sync_engine.dart';

/// Chuyến đi + số đặt chỗ trong đó.
class TripSummary {
  const TripSummary({required this.id, this.title, this.destination, this.startsOn, this.endsOn, this.itemCount = 0});
  final String id;
  final String? title;
  final String? destination;
  /// 'YYYY-MM-DD' theo giờ địa phương in trên vé.
  final String? startsOn;
  final String? endsOn;
  final int itemCount;

  /// Còn hoạt động (chưa qua) tính theo ngày [today]: như `max_active_trips` trên server.
  bool activeOn(String today) => endsOn == null || endsOn!.compareTo(today) >= 0;

  /// Khoảng ngày chồng với [from, to] (cho phép cách nhau [slackDays] ngày): gợi ý gộp đặt chỗ mới vào chuyến này.
  bool overlaps(String from, String to, {int slackDays = 1}) {
    if (startsOn == null) return false;
    final s = CivilDate.parse(startsOn!).addDays(-slackDays).toIso();
    final e = CivilDate.parse(endsOn ?? startsOn!).addDays(slackDays).toIso();
    return from.compareTo(e) <= 0 && to.compareTo(s) >= 0;
  }
}

/// 1 đặt chỗ trong timeline chuyến đi (UX §2.5): item + chi tiết đặt chỗ.
class TripSegment {
  const TripSegment({required this.item, this.bookingType, this.origin, this.destination, this.confirmationCode});
  final ItemView item;
  final String? bookingType;
  final Map<String, Object?>? origin;
  final Map<String, Object?>? destination;
  final String? confirmationCode;
}

/// Đặt chỗ đã có (để màn Xem lại nhận ra vé nhập lại: trùng thì bỏ, đổi giờ thì đề xuất cập nhật).
class ExistingBooking {
  const ExistingBooking({
    required this.itemId,
    required this.confirmationCode,
    this.bookingType,
    this.carrierCode,
    this.number,
    this.originCode,
    this.destinationCode,
    this.startsAt,
    this.startDate,
    this.tripId,
  });
  final String itemId;
  final String confirmationCode;
  final String? bookingType;
  final String? carrierCode;
  final String? number;
  final String? originCode;
  final String? destinationCode;
  final DateTime? startsAt;
  final String? startDate;
  final String? tripId;
}

/// Chuyến đi (S6, US-20/21). Giới hạn `max_active_trips` do server kiểm khi đồng bộ; app kiểm trước nếu đã có `quota_status`.
class TripsRepository {
  TripsRepository(this.engine, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final SyncEngine engine;
  final DateTime Function() _now;
  AppDatabase get _db => engine.db;

  Future<String> create({required String title, String? destination, String? startsOn, String? endsOn}) async {
    final t = title.trim();
    if (t.isEmpty) throw ArgumentError.value(title, 'title', 'không được rỗng');
    final id = uuidV7(nowMillis: _now().millisecondsSinceEpoch);
    await engine.edit(SyncTable.trips, id, {'title': t, 'destination': ?destination, 'starts_on': ?startsOn, 'ends_on': ?endsOn});
    return id;
  }

  /// Nới khoảng ngày của chuyến cho vừa đặt chỗ mới thêm vào.
  Future<void> widen(String id, {required String from, required String to}) async {
    final row = await (_db.select(_db.trips)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    final s = row.startsOn == null || from.compareTo(row.startsOn!) < 0 ? from : row.startsOn!;
    final e = row.endsOn == null || to.compareTo(row.endsOn!) > 0 ? to : row.endsOn!;
    if (s != row.startsOn || e != row.endsOn) await engine.edit(SyncTable.trips, id, {'starts_on': s, 'ends_on': e});
  }

  Future<void> rename(String id, String title) {
    final t = title.trim();
    if (t.isEmpty) throw ArgumentError.value(title, 'title', 'không được rỗng');
    return engine.edit(SyncTable.trips, id, {'title': t});
  }

  /// Xóa chuyến: đặt chỗ vẫn giữ, chỉ bỏ khỏi chuyến.
  Future<void> delete(String id) async {
    final members = await (_db.select(_db.items)..where((t) => t.tripId.equals(id) & t.deletedAt.isNull())).get();
    for (final m in members) {
      await engine.edit(SyncTable.items, m.id, {'trip_id': null});
    }
    await engine.delete(SyncTable.trips, id);
  }

  Future<List<TripSummary>> trips() async {
    final rows = await (_db.select(_db.trips)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.startsOn)]))
        .get();
    final counts = <String, int>{};
    for (final i in await (_db.select(_db.items)..where((t) => t.tripId.isNotNull() & t.deletedAt.isNull())).get()) {
      counts[i.tripId!] = (counts[i.tripId!] ?? 0) + 1;
    }
    return [
      for (final r in rows)
        TripSummary(id: r.id, title: r.title, destination: r.destination, startsOn: r.startsOn, endsOn: r.endsOn, itemCount: counts[r.id] ?? 0),
    ];
  }

  Stream<List<TripSummary>> watchTrips() async* {
    yield await trips();
    await for (final _ in _db.tableUpdates(TableUpdateQuery.onAllTables([_db.trips, _db.items]))) {
      yield await trips();
    }
  }

  /// Số chuyến còn hoạt động trên máy (cách đếm `max_active_trips`, data-model §4), gồm cả chuyến tạo offline chưa đồng bộ.
  Future<int> activeCount(String today) async => (await trips()).where((t) => t.activeOn(today)).length;

  Future<TripSummary?> trip(String id) async => (await trips()).where((t) => t.id == id).firstOrNull;

  /// Đặt chỗ của chuyến theo thời điểm bắt đầu.
  Future<List<TripSegment>> segments(String tripId) async {
    final items = await (_db.select(_db.items)..where((t) => t.tripId.equals(tripId) & t.deletedAt.isNull())).get();
    final details = {
      for (final b in await (_db.select(_db.bookingDetails)..where((t) => t.itemId.isIn(items.map((i) => i.id)) & t.deletedAt.isNull())).get())
        b.itemId: b,
    };
    int key(Item i) =>
        i.startsAt ?? (i.startDate == null ? 0 : DateTime.parse('${i.startDate}T00:00:00Z').millisecondsSinceEpoch);
    items.sort((a, b) => key(a).compareTo(key(b)));
    Map<String, Object?>? json(String? s) => s == null ? null : (jsonDecode(s) as Map).cast<String, Object?>();
    return [
      for (final i in items)
        TripSegment(
          item: ItemView.fromRow(i),
          bookingType: details[i.id]?.bookingType,
          origin: json(details[i.id]?.origin),
          destination: json(details[i.id]?.destination),
          confirmationCode: details[i.id]?.confirmationCode,
        ),
    ];
  }

  Stream<List<TripSegment>> watchSegments(String tripId) async* {
    yield await segments(tripId);
    await for (final _ in _db.tableUpdates(TableUpdateQuery.onAllTables([_db.items, _db.bookingDetails]))) {
      yield await segments(tripId);
    }
  }

  /// Loại đặt chỗ, múi giờ nơi đến và tên chuyến của các item (cho thẻ lịch hẹn trên tab Lịch); item không phải đặt chỗ thì bỏ qua.
  Future<Map<String, ({String? bookingType, String? destinationTz, String? tripTitle})>> bookingInfo(Iterable<String> itemIds) async {
    final ids = itemIds.toSet();
    if (ids.isEmpty) return const {};
    final items = await (_db.select(_db.items)..where((t) => t.id.isIn(ids))).get();
    final details = {
      for (final b in await (_db.select(_db.bookingDetails)..where((t) => t.itemId.isIn(ids) & t.deletedAt.isNull())).get()) b.itemId: b,
    };
    final tripIds = {for (final i in items) ?i.tripId};
    final titles = tripIds.isEmpty
        ? const <String, String?>{}
        : {for (final t in await (_db.select(_db.trips)..where((t) => t.id.isIn(tripIds) & t.deletedAt.isNull())).get()) t.id: t.title};
    String? tz(String? place) => place == null ? null : (jsonDecode(place) as Map)['tz'] as String?;
    return {
      for (final i in items)
        i.id: (bookingType: details[i.id]?.bookingType, destinationTz: tz(details[i.id]?.destination), tripTitle: titles[i.tripId]),
    };
  }

  /// Đặt chỗ đã có với 1 trong [codes] (so không phân biệt hoa thường).
  Future<List<ExistingBooking>> bookingsWithCodes(Iterable<String> codes) async {
    final wanted = {for (final c in codes) c.toUpperCase()};
    if (wanted.isEmpty) return const [];
    final rows = await (_db.select(_db.bookingDetails)..where((t) => t.deletedAt.isNull() & t.confirmationCode.isNotNull())).get();
    final hits = rows.where((b) => wanted.contains(b.confirmationCode!.toUpperCase())).toList();
    if (hits.isEmpty) return const [];
    final items = {
      for (final i in await (_db.select(_db.items)..where((t) => t.id.isIn(hits.map((b) => b.itemId)) & t.deletedAt.isNull())).get()) i.id: i,
    };
    String? code(String? place) => place == null ? null : (jsonDecode(place) as Map)['code'] as String?;
    return [
      for (final b in hits)
        if (items[b.itemId] case final i?)
          ExistingBooking(
            itemId: i.id,
            confirmationCode: b.confirmationCode!,
            bookingType: b.bookingType,
            carrierCode: b.carrierCode,
            number: b.number,
            originCode: code(b.origin),
            destinationCode: code(b.destination),
            startsAt: i.startsAt == null ? null : DateTime.fromMillisecondsSinceEpoch(i.startsAt!, isUtc: true),
            startDate: i.startDate,
            tripId: i.tripId,
          ),
    ];
  }
}
