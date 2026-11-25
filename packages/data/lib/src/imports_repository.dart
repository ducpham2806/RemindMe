import 'package:drift/drift.dart';
import 'package:remindme_core/remindme_core.dart';

import 'database.dart';
import 'items_repository.dart';
import 'lists_repository.dart';
import 'sync_engine.dart';
import 'trips_repository.dart';

/// 1 việc/sự kiện đã qua màn Xem lại, sẵn sàng ghi (thời điểm đã đổi sang UTC + tz IANA ở tầng app).
class ImportedItem {
  const ImportedItem({
    required this.title,
    this.kind = 'task',
    this.startsAt,
    this.tz,
    this.startDate,
    this.endsAt,
    this.endTz,
    this.endDate,
    this.priority = 0,
    this.tags = const [],
    this.notes,
    this.locationText,
    this.checklist = const [],
    this.done = false,
    this.recurrence,
    this.recurrenceStart,
    this.reminderOffsets = const [],
    this.absoluteReminders = const [],
    this.listName,
    this.booking,
    this.tripIndex,
    this.updateItemId,
  });

  final String title;
  final String kind;
  final DateTime? startsAt;
  final String? tz;
  final String? startDate;
  final DateTime? endsAt;
  final String? endTz;
  final String? endDate;
  final int priority;
  final List<String> tags;
  final String? notes;
  final String? locationText;
  final List<({String text, bool done})> checklist;
  final bool done;
  /// Dạng hàng `recurrences` (kind + rrule/calendar).
  final Map<String, Object?>? recurrence;
  final DateTime? recurrenceStart;
  final List<int> reminderOffsets;
  /// Nhắc vào thời điểm cố định (UTC), ví dụ khách sạn 18:00 hôm trước nhận phòng.
  final List<DateTime> absoluteReminders;
  /// Hàng `booking_details` (không có `passengers`: T0/T2 không trả tên hành khách).
  final Map<String, Object?>? booking;
  /// Chỉ số trong `trips` của [ImportsRepository.commit]; null = không thuộc chuyến nào.
  final int? tripIndex;
  /// Đặt chỗ đã có cùng mã nhưng giờ khác (đổi giờ bay): cập nhật item này thay vì tạo mới.
  final String? updateItemId;
  /// Tên list đề xuất: khớp list có sẵn (không dấu, bỏ khoảng trắng) hoặc tạo mới.
  final String? listName;
}

/// Thông tin của lần nhập (hàng `imports`). [kind] theo cột `imports.kind`: image, pdf, xlsx, md, email, ics, pkpass...
class ImportRecord {
  const ImportRecord({
    required this.kind,
    this.mime,
    this.bytes,
    this.sha256,
    this.docType,
    this.docLanguage,
    this.tierUsed = 't0',
    this.templateId,
    this.templateVersion,
  });

  /// Giá trị CHECK của `imports.tier_used` trên server: sai thì cả lần nhập (và item trỏ về nó) bị từ chối khi đồng bộ.
  static const tiers = {'t0', 't1t2', 't3_apple', 't3_gemini', 't4'};
  /// Giá trị CHECK của `imports.kind`.
  static const kinds = {'image', 'pdf', 'xlsx', 'md', 'email', 'voice', 'text', 'ics', 'pkpass'};

  final String kind;
  final String? mime;
  final int? bytes;
  final String? sha256;
  final String? docType;
  final String? docLanguage;
  final String tierUsed;
  final String? templateId;
  final int? templateVersion;
}

/// Chuyến đi gợi ý ở màn Xem lại (US-21): gộp vào chuyến có sẵn ([existingTripId]) hoặc tạo mới.
class TripDraft {
  const TripDraft({this.existingTripId, this.title, this.destination, required this.startsOn, required this.endsOn});
  final String? existingTripId;
  final String? title;
  final String? destination;
  final String startsOn;
  final String endsOn;
}

class ImportResult {
  const ImportResult({
    required this.importId,
    required this.itemIds,
    required this.createdListIds,
    required this.pendingQuota,
    this.tripIds = const [],
    this.updatedItemIds = const [],
  });
  final String importId;
  final List<String> itemIds;
  final List<String> createdListIds;
  /// Vượt `smart_imports_per_month` khi chưa kiểm được với server: item lưu ở `pending_quota` (ADR-008).
  final bool pendingQuota;
  /// Theo thứ tự `trips` truyền vào commit (chuyến mới hoặc có sẵn).
  final List<String> tripIds;
  final List<String> updatedItemIds;
}

/// Ghi kết quả màn Xem lại: 1 hàng `imports` + các item trỏ về nó (`import_id`). Luôn qua [SyncEngine] (ADR-012).
class ImportsRepository {
  ImportsRepository(this.engine, this.items, this.lists, {TripsRepository? trips, DateTime Function()? now})
      : trips = trips ?? TripsRepository(engine, now: now),
        _now = now ?? DateTime.now;

  final SyncEngine engine;
  final ItemsRepository items;
  final ListsRepository lists;
  final TripsRepository trips;
  final DateTime Function() _now;

  AppDatabase get _db => engine.db;

  /// Loại tính vào `smart_imports_per_month` (giống `app.usage_for` trên server; .ics, .pkpass, .md không tính).
  static const smartKinds = {'image', 'pdf', 'xlsx', 'email'};

  /// Lượt nhập thông minh trong tháng hiện tại theo [deviceTz], tính cả bản đã xóa, trừ `failed` (như server).
  Future<int> smartImportsThisMonth(String deviceTz) async {
    final wall = TimeZones.toWall(_now(), deviceTz);
    final first = TimeZones.toUtc(CivilDateTime(CivilDate(wall.date.year, wall.date.month, 1)), deviceTz).utc;
    final rows = await (_db.select(_db.imports)
          ..where((t) =>
              t.kind.isIn(smartKinds) &
              (t.status.isNull() | t.status.isNotValue('failed')) &
              t.createdAt.isBiggerOrEqualValue(first.millisecondsSinceEpoch)))
        .get();
    return rows.length;
  }

  Future<ImportResult> commit(
    ImportRecord record,
    List<ImportedItem> drafts, {
    required String deviceTz,
    String? defaultListId,
    QuotaStatus? quota,
    List<TripDraft> trips = const [],
  }) async {
    if (!ImportRecord.tiers.contains(record.tierUsed)) throw ArgumentError.value(record.tierUsed, 'tierUsed', 'không có trong CHECK của server');
    if (!ImportRecord.kinds.contains(record.kind)) throw ArgumentError.value(record.kind, 'kind', 'không có trong CHECK của server');
    var pending = false;
    if (quota != null && smartKinds.contains(record.kind) && !quota.isUnlimited(EntitlementKey.smartImportsPerMonth)) {
      final used = await smartImportsThisMonth(deviceTz);
      pending = used + 1 > quota.limit(EntitlementKey.smartImportsPerMonth);
    }
    final nowMs = _now().millisecondsSinceEpoch;
    final importId = uuidV7(nowMillis: nowMs);
    await engine.edit(SyncTable.imports, importId, {
      'kind': record.kind,
      'status': 'committed',
      'tier_used': record.tierUsed,
      'mime': ?record.mime,
      'bytes': ?record.bytes,
      'sha256': ?record.sha256,
      'doc_type': ?record.docType,
      'doc_language': ?record.docLanguage,
      'template_id': ?record.templateId,
      'template_version': ?record.templateVersion,
    });
    // created_at do server đặt (không đồng bộ từ máy); local cần để đếm hạn mức trước khi sync.
    await (_db.update(_db.imports)..where((t) => t.id.equals(importId))).write(ImportsCompanion(createdAt: Value(nowMs)));

    final listIds = <String, String>{};
    final created = <String>[];
    Future<String?> listFor(String? name) async {
      final n = name?.trim();
      if (n == null || n.isEmpty) return defaultListId;
      final key = foldForSearch(n).replaceAll(' ', '');
      if (listIds[key] case final id?) return id;
      var id = await lists.matchTag(n);
      if (id == null) {
        id = await lists.create(n);
        created.add(id);
      }
      return listIds[key] = id;
    }

    // Chuyến đi trước (item trỏ tới bằng trip_id): có sẵn thì nới khoảng ngày, không thì tạo.
    final tripIds = <String>[];
    for (final t in trips) {
      if (t.existingTripId case final id?) {
        await this.trips.widen(id, from: t.startsOn, to: t.endsOn);
        tripIds.add(id);
      } else {
        tripIds.add(await this.trips.create(title: t.title ?? '', destination: t.destination, startsOn: t.startsOn, endsOn: t.endsOn));
      }
    }
    String? tripOf(ImportedItem d) => d.tripIndex == null || d.tripIndex! >= tripIds.length ? null : tripIds[d.tripIndex!];

    final ids = <String>[];
    final updated = <String>[];
    for (final d in drafts) {
      if (d.title.trim().isEmpty) continue;
      if (d.updateItemId case final existing?) {
        await items.updateBooking(
          existing,
          startsAt: d.startsAt,
          tz: d.tz,
          startDate: d.startDate,
          endsAt: d.endsAt,
          endTz: d.endTz,
          endDate: d.endDate,
          booking: d.booking,
          absoluteReminders: d.absoluteReminders,
          tripId: tripOf(d),
        );
        updated.add(existing);
        continue;
      }
      ids.add(await items.create(
        title: d.title,
        kind: d.kind,
        listId: await listFor(d.listName),
        startsAt: d.startsAt,
        tz: d.tz,
        startDate: d.startDate,
        endsAt: d.endsAt,
        endTz: d.endTz,
        endDate: d.endDate,
        priority: d.priority.clamp(0, 3),
        tags: d.tags,
        source: _itemSource(record.kind),
        notes: d.notes,
        location: d.locationText == null ? null : {'name': d.locationText},
        checklist: [for (final c in d.checklist) {'text': c.text, 'done': c.done}],
        status: pending ? 'pending_quota' : (d.done ? 'done' : 'open'),
        recurrence: d.recurrence,
        recurrenceStart: d.recurrenceStart,
        reminderOffsets: d.done ? const [] : d.reminderOffsets,
        absoluteReminders: d.done ? const [] : d.absoluteReminders,
        importId: importId,
        tripId: tripOf(d),
        booking: d.booking,
      ));
    }
    return ImportResult(
      importId: importId,
      itemIds: ids,
      createdListIds: created,
      pendingQuota: pending,
      tripIds: tripIds,
      updatedItemIds: updated,
    );
  }

  /// `imports.kind` → `items.source` (2 enum khác nhau trên server).
  static String _itemSource(String kind) => switch (kind) {
        'image' || 'pdf' || 'xlsx' || 'md' || 'email' || 'ics' || 'pkpass' || 'voice' => kind,
        _ => 'manual',
      };
}
