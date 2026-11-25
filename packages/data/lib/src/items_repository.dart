import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:remindme_core/remindme_core.dart';

import 'database.dart';
import 'reminders/planner.dart';
import 'reminders/scheduler.dart' show plannerItemOf;
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
    this.occurrenceAt,
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
  /// Khác null: dòng này là 1 lần của chuỗi lặp (khóa `occurrence_log`); Xong chỉ đóng lần này.
  final DateTime? occurrenceAt;

  bool get isOccurrence => occurrenceAt != null;
  /// Khóa duy nhất trên danh sách (1 item lặp có thể có nhiều lần trong ngày).
  String get rowKey => occurrenceAt == null ? id : '$id@${occurrenceAt!.millisecondsSinceEpoch}';

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

  /// Màn Hôm nay cho ngày [day]: item 1 lần (mở, hoặc xong trong ngày) + **từng lần** của chuỗi lặp rơi vào ngày đó
  /// (trạng thái lấy từ `occurrence_log`). Lần lặp đã qua của ngày trước không dồn vào Quá hạn.
  /// [deviceTz]: múi giờ nơi máy đang ở (item floating và cả ngày).
  Stream<TodaySections> watchToday(DayWindow day, {required String deviceTz}) async* {
    final changes = _db.tableUpdates(TableUpdateQuery.onAllTables([_db.items, _db.recurrences, _db.occurrenceLog]));
    yield await _today(day, deviceTz);
    await for (final _ in changes) {
      yield await _today(day, deviceTz);
    }
  }

  Future<TodaySections> _today(DayWindow day, String deviceTz) async {
    final rows = await (_db.select(_db.items)
          ..where((t) =>
              t.deletedAt.isNull() &
              (t.status.isIn(const ['open', 'pending_quota']) |
                  (t.status.equals('done') & t.completedAt.isBiggerOrEqualValue(day.startUtc.millisecondsSinceEpoch)))))
        .get();
    final recs = {for (final r in await (_db.select(_db.recurrences)..where((t) => t.deletedAt.isNull())).get()) r.itemId: r};
    final views = <ItemView>[];
    final recurring = <Item>[];
    for (final r in rows) {
      if (recs.containsKey(r.id) && r.status != 'done') {
        recurring.add(r);
      } else if (!recs.containsKey(r.id)) {
        views.add(ItemView.fromRow(r));
      }
    }
    if (recurring.isNotEmpty) {
      final log = {
        for (final o in await (_db.select(_db.occurrenceLog)
              ..where((t) =>
                  t.deletedAt.isNull() &
                  t.itemId.isIn(recurring.map((r) => r.id)) &
                  t.occurrenceAt.isBetweenValues(
                      day.startUtc.subtract(const Duration(days: 1)).millisecondsSinceEpoch, day.endUtc.millisecondsSinceEpoch)))
            .get())
          (o.itemId, o.occurrenceAt): o.status,
      };
      for (final r in recurring) {
        final base = ItemView.fromRow(r);
        final pi = plannerItemOf(r, recs[r.id], deviceTz: deviceTz);
        // Cả ngày: lần có ngày = ngày đang xem; có giờ: lần trong [start, end).
        final occs = expandOccurrences(pi, day.startUtc.subtract(const Duration(days: 1)), day.endUtc.add(const Duration(days: 1)),
            deviceTz: deviceTz, allDayTime: CivilTime(0));
        for (final o in occs) {
          final inDay = o.allDay
              ? o.date.toIso() == day.localDate
              : !o.at.isBefore(day.startUtc) && o.at.isBefore(day.endUtc);
          if (!inDay) continue;
          final status = log[(r.id, o.at.millisecondsSinceEpoch)];
          if (status == 'skipped') continue;
          views.add(ItemView(
            id: base.id,
            title: base.title,
            kind: base.kind,
            status: status == 'done' ? 'done' : 'open',
            notes: base.notes,
            listId: base.listId,
            priority: base.priority,
            startsAt: o.allDay ? null : o.at,
            allDay: o.allDay,
            startDate: o.allDay ? o.date.toIso() : null,
            tz: base.tz,
            tags: base.tags,
            completedAt: status == 'done' ? (o.at.isBefore(day.startUtc) ? day.startUtc : o.at) : null,
            occurrenceAt: o.at,
          ));
        }
      }
    }
    return TodaySections.partition(views, day);
  }

  /// Số item (mở hoặc đã xong) theo ngày địa phương 'YYYY-MM-DD' trong [from, to] (gồm 2 đầu), cho chấm trên lịch tháng (UX §2.6).
  /// Item có giờ tính theo ngày ở [deviceTz]; chuỗi lặp trải từng lần (bỏ lần đã bỏ qua).
  Future<Map<String, int>> countsByDay(CivilDate from, CivilDate to, {required String deviceTz}) async {
    final out = <String, int>{};
    void add(CivilDate d) {
      if (d.isBefore(from) || d.isAfter(to)) return;
      out.update(d.toIso(), (n) => n + 1, ifAbsent: () => 1);
    }

    final rows = await (_db.select(_db.items)
          ..where((t) => t.deletedAt.isNull() & t.status.isIn(const ['open', 'pending_quota', 'done'])))
        .get();
    final recs = {for (final r in await (_db.select(_db.recurrences)..where((t) => t.deletedAt.isNull())).get()) r.itemId: r};
    final fromUtc = TimeZones.toUtc(CivilDateTime(from.addDays(-1), CivilTime(0)), deviceTz).utc;
    final toUtc = TimeZones.toUtc(CivilDateTime(to.addDays(2), CivilTime(0)), deviceTz).utc;
    final recurring = rows.where((r) => recs.containsKey(r.id) && r.status != 'done').toList();
    final skipped = recurring.isEmpty
        ? const <(String, int)>{}
        : {
            for (final o in await (_db.select(_db.occurrenceLog)
                  ..where((t) =>
                      t.deletedAt.isNull() &
                      t.status.equals('skipped') &
                      t.itemId.isIn(recurring.map((r) => r.id)) &
                      t.occurrenceAt.isBetweenValues(fromUtc.millisecondsSinceEpoch, toUtc.millisecondsSinceEpoch)))
                .get())
              (o.itemId, o.occurrenceAt),
          };
    for (final r in rows) {
      if (recs.containsKey(r.id)) {
        if (r.status == 'done') continue;
        final pi = plannerItemOf(r, recs[r.id], deviceTz: deviceTz);
        for (final o in expandOccurrences(pi, fromUtc, toUtc, deviceTz: deviceTz, allDayTime: CivilTime(0))) {
          if (skipped.contains((r.id, o.at.millisecondsSinceEpoch))) continue;
          add(o.allDay ? o.date : TimeZones.toWall(o.at, deviceTz).date);
        }
      } else if (r.startDate != null && ((r.allDay ?? false) || r.startsAt == null)) {
        add(CivilDate.parse(r.startDate!));
      } else if (r.startsAt != null) {
        add(TimeZones.toWall(DateTime.fromMillisecondsSinceEpoch(r.startsAt!, isUtc: true), deviceTz).date);
      }
    }
    return out;
  }

  Stream<Map<String, int>> watchCountsByDay(CivilDate from, CivilDate to, {required String deviceTz}) async* {
    yield await countsByDay(from, to, deviceTz: deviceTz);
    await for (final _ in _db.tableUpdates(TableUpdateQuery.onAllTables([_db.items, _db.recurrences, _db.occurrenceLog]))) {
      yield await countsByDay(from, to, deviceTz: deviceTz);
    }
  }

  /// id các item có lặp (để hiện biểu tượng 🔁).
  Stream<Set<String>> watchRecurringIds() {
    final q = _db.select(_db.recurrences)..where((t) => t.deletedAt.isNull());
    return q.watch().map((rows) => {for (final r in rows) r.itemId});
  }

  Future<bool> isRecurring(String itemId) async =>
      await (_db.select(_db.recurrences)..where((t) => t.itemId.equals(itemId) & t.deletedAt.isNull())).getSingleOrNull() != null;

  /// Quy tắc lặp của item (dạng hàng `recurrences`) hoặc null; cập nhật khi đổi.
  Stream<Map<String, Object?>?> watchRecurrence(String itemId) =>
      (_db.select(_db.recurrences)..where((t) => t.itemId.equals(itemId) & t.deletedAt.isNull())).watchSingleOrNull().map((r) => r == null
          ? null
          : {
              'kind': r.kind,
              'rrule': r.rrule,
              'calendar': r.calendar == null ? null : jsonDecode(r.calendar!),
              'interval_days': r.intervalDays,
            });

  Future<Map<String, Object?>?> recurrenceOf(String itemId) async {
    final r = await (_db.select(_db.recurrences)..where((t) => t.itemId.equals(itemId) & t.deletedAt.isNull())).getSingleOrNull();
    if (r == null) return null;
    return {
      'kind': r.kind,
      'rrule': r.rrule,
      'calendar': r.calendar == null ? null : jsonDecode(r.calendar!),
      'interval_days': r.intervalDays,
    };
  }

  /// Tìm theo tiêu đề, ghi chú, tag; không phân biệt hoa thường/dấu (`foldForSearch`). Việc đang mở trước, rồi mới nhất trước.
  /// Lọc trong Dart vì `lower()` của SQLite không hiểu Unicode; đủ nhanh tới vài chục nghìn mục.
  Future<List<ItemView>> search(String query, {int limit = 100}) async {
    final terms = foldForSearch(query).split(' ').where((t) => t.isNotEmpty).toList();
    if (terms.isEmpty) return const [];
    final rows = await (_db.select(_db.items)..where((t) => t.deletedAt.isNull() & t.status.isNotIn(const ['archived']))).get();
    final hits = <ItemView>[];
    for (final r in rows) {
      final hay = foldForSearch('${r.title ?? ''} ${r.notes ?? ''} ${r.tags ?? ''}');
      if (terms.every(hay.contains)) hits.add(ItemView.fromRow(r));
    }
    hits.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      return b.id.compareTo(a.id);
    });
    return hits.take(limit).toList();
  }

  Future<ItemView?> getItem(String id) async {
    final r = await (_db.select(_db.items)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return r == null ? null : ItemView.fromRow(r);
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
    Map<String, Object?>? recurrence,
    DateTime? recurrenceStart,
    List<int> reminderOffsets = const [],
    DateTime? endsAt,
    String? endTz,
    String? endDate,
    Map<String, Object?>? location,
    List<Map<String, Object?>> checklist = const [],
    String status = 'open',
    String? importId,
    String? tripId,
    List<DateTime> absoluteReminders = const [],
    Map<String, Object?>? booking,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(title, 'title', 'không được rỗng');
    if (startsAt != null && tz == null) throw ArgumentError('startsAt cần tz IANA đi kèm');
    if (recurrence != null && recurrenceStart == null) throw ArgumentError('recurrence cần recurrenceStart (dtstart)');
    final id = uuidV7(nowMillis: _now().millisecondsSinceEpoch);
    await engine.edit(SyncTable.items, id, {
      'kind': kind,
      'title': trimmed,
      'status': status,
      if (status == 'done') 'completed_at': _now().toUtc().toIso8601String(),
      'priority': priority,
      'tags': tags,
      'source': source,
      'all_day': startDate != null && startsAt == null,
      'list_id': ?listId,
      if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
      'tz': ?tz,
      'start_date': ?startDate,
      'notes': ?notes,
      if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
      'end_tz': ?endTz,
      'end_date': ?endDate,
      'location': ?location,
      if (checklist.isNotEmpty) 'checklist': checklist,
      'import_id': ?importId,
      'trip_id': ?tripId,
      // Việc lặp "8h sáng mỗi ngày" kêu theo giờ nơi đang đứng (reminder-engine.md §5).
      if (recurrence != null) 'time_mode': kind == 'task' || kind == 'habit' ? 'floating' : 'fixed',
    });
    if (recurrence != null) {
      await engine.edit(SyncTable.recurrences, id, {
        ...recurrence,
        'dtstart': recurrenceStart!.toUtc().toIso8601String(),
      });
    }
    if (booking != null) await engine.edit(SyncTable.bookingDetails, id, booking);
    for (final off in reminderOffsets) {
      await addReminder(id, offsetMinutes: off);
    }
    for (final at in absoluteReminders) {
      await addReminderAt(id, at);
    }
    return id;
  }

  /// Vé nhập lại có giờ mới (đổi giờ bay): cập nhật thời điểm + chi tiết đặt chỗ của item đã có, giữ nhắc theo offset
  /// (lập lại theo giờ mới). Nhắc tuyệt đối cũ bị thay bằng [absoluteReminders].
  Future<void> updateBooking(
    String id, {
    DateTime? startsAt,
    String? tz,
    String? startDate,
    DateTime? endsAt,
    String? endTz,
    String? endDate,
    Map<String, Object?>? booking,
    List<DateTime>? absoluteReminders,
    String? tripId,
  }) async {
    if (startsAt != null && tz == null) throw ArgumentError('startsAt cần tz IANA đi kèm');
    await engine.edit(SyncTable.items, id, {
      'starts_at': startsAt?.toUtc().toIso8601String(),
      'tz': tz,
      'start_date': startDate,
      'all_day': startDate != null && startsAt == null,
      'ends_at': endsAt?.toUtc().toIso8601String(),
      'end_tz': endTz,
      'end_date': endDate,
      'trip_id': ?tripId,
    });
    if (booking != null) await engine.edit(SyncTable.bookingDetails, id, booking);
    if (absoluteReminders != null) {
      final old = await (_db.select(_db.reminders)
            ..where((t) => t.itemId.equals(id) & t.deletedAt.isNull() & t.triggerKind.equals('absolute')))
          .get();
      for (final r in old) {
        await engine.delete(SyncTable.reminders, r.id);
      }
      for (final at in absoluteReminders) {
        await addReminderAt(id, at);
      }
    }
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

  /// Đặt thời điểm: [startsAt] (UTC) + [tz] cho việc có giờ, hoặc [startDate] cho việc cả ngày; cả hai null = bỏ ngày.
  Future<void> setSchedule(String id, {DateTime? startsAt, String? tz, String? startDate}) {
    if (startsAt != null && tz == null) throw ArgumentError('startsAt cần tz IANA đi kèm');
    if (startsAt != null && startDate != null) throw ArgumentError('chọn startsAt hoặc startDate');
    return engine.edit(SyncTable.items, id, {
      'starts_at': startsAt?.toUtc().toIso8601String(),
      'start_date': startDate,
      'all_day': startDate != null,
      'tz': startsAt != null ? tz : (startDate != null ? tz : null),
    });
  }

  /// Đặt quy tắc lặp ([rule] dạng hàng `recurrences`: kind + rrule/calendar) hoặc bỏ lặp (null).
  Future<void> setRecurrence(String itemId, Map<String, Object?>? rule, {DateTime? start}) async {
    if (rule == null) {
      if (await isRecurring(itemId)) await engine.delete(SyncTable.recurrences, itemId);
      return;
    }
    if (start == null) throw ArgumentError('lặp cần start (dtstart)');
    await engine.edit(SyncTable.recurrences, itemId, {
      'kind': rule['kind'],
      'rrule': rule['rrule'],
      'calendar': rule['calendar'],
      'dtstart': start.toUtc().toIso8601String(),
    });
    // Việc lặp kêu theo giờ nơi đang đứng (reminder-engine.md §5).
    final item = await (_db.select(_db.items)..where((t) => t.id.equals(itemId))).getSingleOrNull();
    if (item != null && (item.kind == 'task' || item.kind == 'habit') && item.timeMode != 'floating') {
      await engine.edit(SyncTable.items, itemId, {'time_mode': 'floating'});
    }
  }

  /// Chuyển item sang list [listId] (null = Inbox).
  Future<void> setList(String id, String? listId) => engine.edit(SyncTable.items, id, {'list_id': listId});

  Future<void> setPriority(String id, int priority) {
    if (priority < 0 || priority > 3) throw RangeError.range(priority, 0, 3, 'priority');
    return engine.edit(SyncTable.items, id, {'priority': priority});
  }

  Future<void> delete(String id) => engine.delete(SyncTable.items, id);

  // ------------------------------------------------------------------ nhắc (reminders)

  /// Thêm nhắc [offsetMinutes] phút trước giờ của item (0 = đúng giờ).
  Future<String> addReminder(String itemId, {required int offsetMinutes, bool isAlarm = false}) async {
    final id = uuidV7(nowMillis: _now().millisecondsSinceEpoch);
    await engine.edit(SyncTable.reminders, id, {
      'item_id': itemId,
      'trigger_kind': 'offset',
      'offset_minutes': offsetMinutes,
      'channel': const ['push'],
      'is_alarm': isAlarm,
    });
    return id;
  }

  /// Nhắc vào 1 thời điểm cố định (khách sạn: 18:00 hôm trước nhận phòng, 1 giờ trước trả phòng).
  Future<String> addReminderAt(String itemId, DateTime at) async {
    final id = uuidV7(nowMillis: _now().millisecondsSinceEpoch);
    await engine.edit(SyncTable.reminders, id, {
      'item_id': itemId,
      'trigger_kind': 'absolute',
      'at': at.toUtc().toIso8601String(),
      'channel': const ['push'],
      'is_alarm': false,
    });
    return id;
  }

  Stream<bool> watchHasReminders() =>
      (_db.select(_db.reminders)..where((t) => t.deletedAt.isNull())..limit(1)).watch().map((r) => r.isNotEmpty);

  Future<void> removeReminder(String reminderId) => engine.delete(SyncTable.reminders, reminderId);

  Future<List<Reminder>> remindersOf(String itemId) => (_db.select(_db.reminders)
        ..where((t) => t.itemId.equals(itemId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.offsetMinutes)]))
      .get();

  Stream<List<Reminder>> watchReminders(String itemId) => (_db.select(_db.reminders)
        ..where((t) => t.itemId.equals(itemId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.offsetMinutes)]))
      .watch();

  /// Hoãn (action Snooze trên thông báo): kêu lại lúc [until].
  Future<void> snooze(String reminderId, {required DateTime until}) =>
      engine.edit(SyncTable.reminders, reminderId, {'snoozed_until': until.toUtc().toIso8601String()});

  // ------------------------------------------------------------------ từng lần của chuỗi lặp

  /// Xong 1 lần của chuỗi lặp (không đóng cả chuỗi), reminder-engine.md §4.
  Future<void> completeOccurrence(String itemId, DateTime occurrenceAt) => engine.edit(SyncTable.occurrenceLog, itemId, {
        'occurrence_at': occurrenceAt.toUtc().toIso8601String(),
        'status': 'done',
      });

  Future<void> skipOccurrence(String itemId, DateTime occurrenceAt) => engine.edit(SyncTable.occurrenceLog, itemId, {
        'occurrence_at': occurrenceAt.toUtc().toIso8601String(),
        'status': 'skipped',
      });

  /// Hoàn tác "Xong" của 1 lần.
  Future<void> reopenOccurrence(String itemId, DateTime occurrenceAt) =>
      engine.delete(SyncTable.occurrenceLog, itemId, occurrenceAt: occurrenceAt);

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
