import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:remindme_core/remindme_core.dart';

import 'database.dart';
import 'sync_engine.dart';

/// Ngày đang xem theo giờ trên máy: [start, end) theo UTC và ngày lịch 'YYYY-MM-DD' (cho item cả ngày).
/// App tính từ giờ local của máy; package này không giả định múi giờ (AGENTS quy tắc 5).
class DayWindow {
  DayWindow({required this.startUtc, required this.endUtc, required this.localDate})
      : assert(startUtc.isUtc && endUtc.isUtc),
        assert(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(localDate));

  /// Ngày chứa [local] (DateTime theo giờ máy).
  factory DayWindow.ofLocal(DateTime local) {
    final start = DateTime(local.year, local.month, local.day);
    final end = DateTime(local.year, local.month, local.day + 1);
    return DayWindow(startUtc: start.toUtc(), endUtc: end.toUtc(), localDate: isoDate(start));
  }

  final DateTime startUtc;
  final DateTime endUtc;
  final String localDate;

  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Item đã giải mã từ hàng local, cho UI.
class ItemView {
  const ItemView({
    required this.id,
    required this.title,
    required this.kind,
    required this.status,
    this.notes,
    this.listId,
    this.priority = 0,
    this.startsAt,
    this.endsAt,
    this.allDay = false,
    this.startDate,
    this.tz,
    this.tags = const [],
    this.completedAt,
  });

  factory ItemView.fromRow(Item r) => ItemView(
        id: r.id,
        title: r.title ?? '',
        kind: r.kind ?? 'task',
        status: r.status ?? 'open',
        notes: r.notes,
        listId: r.listId,
        priority: r.priority ?? 0,
        startsAt: r.startsAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.startsAt!, isUtc: true),
        endsAt: r.endsAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.endsAt!, isUtc: true),
        allDay: r.allDay ?? false,
        startDate: r.startDate,
        tz: r.tz,
        tags: r.tags == null ? const [] : (jsonDecode(r.tags!) as List<Object?>).cast<String>(),
        completedAt: r.completedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.completedAt!, isUtc: true),
      );

  final String id;
  final String title;
  final String kind;
  final String status;
  final String? notes;
  final String? listId;
  final int priority;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final String? startDate;
  final String? tz;
  final List<String> tags;
  final DateTime? completedAt;

  bool get isDone => status == 'done';
  bool get hasTime => startsAt != null && !allDay;
  bool get isScheduled => startsAt != null || startDate != null;
}

/// Các nhóm của màn Hôm nay (UX §2.1).
class TodaySections {
  const TodaySections({this.overdue = const [], this.today = const [], this.noTime = const [], this.doneToday = const []});

  final List<ItemView> overdue;
  final List<ItemView> today;
  final List<ItemView> noTime;
  final List<ItemView> doneToday;

  bool get isEmpty => overdue.isEmpty && today.isEmpty && noTime.isEmpty && doneToday.isEmpty;

  /// Chia [items] theo [day]. Hàm thuần để test không cần DB.
  static TodaySections partition(Iterable<ItemView> items, DayWindow day) {
    final overdue = <ItemView>[], today = <ItemView>[], noTime = <ItemView>[], done = <ItemView>[];
    for (final i in items) {
      if (i.isDone) {
        final at = i.completedAt;
        if (at != null && !at.isBefore(day.startUtc) && at.isBefore(day.endUtc)) done.add(i);
        continue;
      }
      if (i.status != 'open' && i.status != 'pending_quota') continue;
      if (i.allDay || (i.startsAt == null && i.startDate != null)) {
        final d = i.startDate;
        if (d == null) continue;
        final c = d.compareTo(day.localDate);
        if (c < 0) {
          overdue.add(i);
        } else if (c == 0) {
          today.add(i);
        }
      } else if (i.startsAt != null) {
        if (i.startsAt!.isBefore(day.startUtc)) {
          overdue.add(i);
        } else if (i.startsAt!.isBefore(day.endUtc)) {
          today.add(i);
        }
      } else if (i.kind == 'task') {
        noTime.add(i);
      }
    }
    int byTime(ItemView a, ItemView b) {
      // Cả ngày đứng đầu, rồi theo giờ, rồi ưu tiên cao trước.
      final ta = a.hasTime ? a.startsAt!.millisecondsSinceEpoch : -1;
      final tb = b.hasTime ? b.startsAt!.millisecondsSinceEpoch : -1;
      return ta != tb ? ta.compareTo(tb) : b.priority.compareTo(a.priority);
    }

    // id là UUIDv7 nên so chuỗi = thứ tự tạo.
    int byPriority(ItemView a, ItemView b) => a.priority != b.priority ? b.priority.compareTo(a.priority) : a.id.compareTo(b.id);
    overdue.sort(byTime);
    today.sort(byTime);
    noTime.sort(byPriority);
    done.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return TodaySections(overdue: overdue, today: today, noTime: noTime, doneToday: done);
  }
}

/// Đọc/ghi item cho UI. Mọi ghi đi qua [SyncEngine.edit]/[SyncEngine.delete] (DB local + outbox cùng transaction).
class ItemsRepository {
  ItemsRepository(this.engine, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SyncEngine engine;
  final DateTime Function() _now;
  AppDatabase get _db => engine.db;

  /// Item chưa xóa còn liên quan tới ngày [day]: đang mở (mọi thời điểm, lọc ở [TodaySections.partition]) hoặc xong trong ngày.
  Stream<TodaySections> watchToday(DayWindow day) {
    final q = _db.select(_db.items)
      ..where((t) =>
          t.deletedAt.isNull() &
          (t.status.isIn(const ['open', 'pending_quota']) |
              (t.status.equals('done') & t.completedAt.isBiggerOrEqualValue(day.startUtc.millisecondsSinceEpoch))));
    return q.watch().map((rows) => TodaySections.partition(rows.map(ItemView.fromRow), day));
  }

  Stream<ItemView?> watchItem(String id) {
    final q = _db.select(_db.items)..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return q.watchSingleOrNull().map((r) => r == null ? null : ItemView.fromRow(r));
  }

  /// Tạo việc. Thời điểm: [startsAt] (UTC) + [tz] IANA, hoặc [startDate] cho việc cả ngày; không có cả hai = chưa đặt giờ.
  Future<String> create({
    required String title,
    String kind = 'task',
    String? listId,
    DateTime? startsAt,
    String? tz,
    String? startDate,
    int priority = 0,
    List<String> tags = const [],
    String source = 'manual',
    String? notes,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(title, 'title', 'không được rỗng');
    if (startsAt != null && tz == null) throw ArgumentError('startsAt cần tz IANA đi kèm');
    final id = uuidV7(nowMillis: _now().millisecondsSinceEpoch);
    await engine.edit(SyncTable.items, id, {
      'kind': kind,
      'title': trimmed,
      'status': 'open',
      'priority': priority,
      'tags': tags,
      'source': source,
      'all_day': startDate != null && startsAt == null,
      'list_id': ?listId,
      if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
      'tz': ?tz,
      'start_date': ?startDate,
      'notes': ?notes,
    });
    return id;
  }

  Future<void> setDone(String id, {required bool done}) => engine.edit(SyncTable.items, id, {
        'status': done ? 'done' : 'open',
        'completed_at': done ? _now().toUtc().toIso8601String() : null,
      });

  Future<void> rename(String id, String title) {
    final t = title.trim();
    if (t.isEmpty) throw ArgumentError.value(title, 'title', 'không được rỗng');
    return engine.edit(SyncTable.items, id, {'title': t});
  }

  /// [baseClock] = clock của notes lúc mở màn sửa, để server phát hiện 2 máy cùng sửa (UX §3.6).
  Future<void> setNotes(String id, String? notes, {String? baseClock}) => engine.edit(
        SyncTable.items,
        id,
        {'notes': (notes == null || notes.trim().isEmpty) ? null : notes},
        baseClock: baseClock == null ? null : {'notes': baseClock},
      );

  Future<void> setPriority(String id, int priority) {
    if (priority < 0 || priority > 3) throw RangeError.range(priority, 0, 3, 'priority');
    return engine.edit(SyncTable.items, id, {'priority': priority});
  }

  Future<void> delete(String id) => engine.delete(SyncTable.items, id);

  /// Clock hiện tại của notes (truyền lại vào [setNotes]).
  Future<String?> notesClock(String id) async {
    final r = await (_db.select(_db.items)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) return null;
    return (jsonDecode(r.fieldClock) as Map<String, Object?>)['notes'] as String?;
  }
}

/// Thông tin của máy cài app, lưu trong DB local (mất khi gỡ app, đúng nghĩa "1 lần mỗi lần cài", ADR-013).
class InstallInfo {
  static const _deviceIdKey = 'device_id';

  static Future<String> deviceId(AppDatabase db) async {
    final existing = await (db.select(db.syncState)..where((s) => s.key.equals(_deviceIdKey))).getSingleOrNull();
    if (existing != null) return existing.value;
    final id = uuidV7();
    await db.into(db.syncState).insert(SyncStateCompanion.insert(key: _deviceIdKey, value: id), mode: InsertMode.insertOrIgnore);
    return (await (db.select(db.syncState)..where((s) => s.key.equals(_deviceIdKey))).getSingle()).value;
  }
}
