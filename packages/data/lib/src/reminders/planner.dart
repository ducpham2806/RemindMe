import 'dart:convert';

import 'package:remindme_core/remindme_core.dart';

/// Item cần lập lịch nhắc (đọc từ DB local).
class PlannerItem {
  const PlannerItem({
    required this.id,
    required this.title,
    this.kind = 'task',
    this.startsAt,
    this.startDate,
    this.allDay = false,
    this.tz,
    this.timeMode = 'fixed',
    this.recurrence,
    this.exdates = const {},
  });

  final String id;
  final String title;
  final String kind;
  final DateTime? startsAt;
  final String? startDate;
  final bool allDay;
  final String? tz;
  /// 'fixed' (theo `tz` của item) | 'floating' (theo múi giờ nơi đang đứng), reminder-engine.md §5.
  final String timeMode;
  final Recurrence? recurrence;
  final Set<CivilDateTime> exdates;
}

class PlannerReminder {
  const PlannerReminder({
    required this.id,
    required this.itemId,
    required this.triggerKind,
    this.at,
    this.offsetMinutes,
    this.isAlarm = false,
    this.snoozedUntil,
  });

  final String id;
  final String itemId;
  /// 'absolute' | 'offset' | 'location' (location: Phase 2, bỏ qua).
  final String triggerKind;
  final DateTime? at;
  /// Số phút **trước** lần của item (0 = đúng giờ).
  final int? offsetMinutes;
  final bool isAlarm;
  final DateTime? snoozedUntil;
}

enum PlannedKind { occurrence, snooze, fallback }

class PlannedNotification {
  const PlannedNotification({
    required this.notificationId,
    required this.reminderId,
    required this.itemId,
    required this.occurrenceAt,
    required this.fireAt,
    required this.title,
    required this.body,
    this.isAlarm = false,
    this.dstAdjusted = false,
    this.kind = PlannedKind.occurrence,
  });

  final int notificationId;
  final String reminderId;
  final String itemId;
  final DateTime occurrenceAt;
  final DateTime fireAt;
  final String title;
  final String body;
  final bool isAlarm;
  final bool dstAdjusted;
  final PlannedKind kind;

  String get contentHash => '$title|$body|$isAlarm|${fireAt.millisecondsSinceEpoch}';

  /// Payload gắn vào thông báo để xử lý action Xong/Hoãn (không chứa nội dung item).
  String get payload => jsonEncode({'i': itemId, 'r': reminderId, 'o': occurrenceAt.millisecondsSinceEpoch});

  @override
  String toString() => '$kind $itemId@${occurrenceAt.toIso8601String()} fire ${fireAt.toIso8601String()}';
}

class PlanResult {
  const PlanResult(this.notifications, {required this.truncated, required this.horizonEnd, required this.dropped});
  final List<PlannedNotification> notifications;
  /// Còn lần nhắc sau giới hạn số thông báo chờ (iOS 64): app phải nạp lại (BGAppRefresh, silent push).
  final bool truncated;
  final DateTime horizonEnd;
  final int dropped;
}

/// Chuỗi đã dịch cho thông báo (app cấp từ ARB theo ngôn ngữ hiện tại, AGENTS quy tắc 5b).
abstract interface class NotificationTexts {
  /// Nội dung 1 lần nhắc của [item] cho lần [occurrenceAt] ([offsetMinutes] trước giờ đó).
  ({String title, String body}) forOccurrence(PlannerItem item, DateTime occurrenceAt, int offsetMinutes);
  ({String title, String body}) forSnooze(PlannerItem item);
  /// Thông báo dự phòng khi bị cắt bởi giới hạn số thông báo (§1 bước 4).
  ({String title, String body}) fallback();
}

/// Rolling window (reminder-engine.md §1): trải mọi nhắc trong [horizon], sắp theo giờ kêu, giữ [maxPending] cái đầu.
/// Hàm thuần: không đọc DB, không gọi OS (dễ test DST, múi giờ, giới hạn).
class ReminderPlanner {
  ReminderPlanner({
    required this.deviceTz,
    required this.maxPending,
    this.horizon = const Duration(days: 14),
    CivilTime? allDayTime,
  }) : allDayTime = allDayTime ?? CivilTime(9);

  /// Múi giờ IANA nơi máy đang ở (dùng cho item `floating` và item cả ngày).
  final String deviceTz;
  /// Số thông báo chờ tối đa của OS cho app (iOS 60 = 64 trừ 4 chừa lại; Android 500).
  final int maxPending;
  final Duration horizon;
  /// Giờ kêu của item cả ngày (cài đặt người dùng; §5 ví dụ 09:00).
  final CivilTime allDayTime;

  /// Ngưỡng dưới đó coi là OS giới hạn chặt (iOS) và chừa 1 chỗ cho thông báo dự phòng.
  static const strictLimit = 100;

  PlanResult plan({
    required List<PlannerItem> items,
    required List<PlannerReminder> reminders,
    required DateTime now,
    required NotificationTexts texts,
    Set<(String, int)> handledOccurrences = const {},
  }) {
    final end = now.add(horizon);
    final byItem = {for (final i in items) i.id: i};
    final out = <int, PlannedNotification>{};

    void add(PlannedNotification n) {
      if (!n.fireAt.isAfter(now) || n.fireAt.isAfter(end)) return;
      final prev = out[n.notificationId];
      if (prev == null || n.fireAt.isBefore(prev.fireAt)) out[n.notificationId] = n;
    }

    for (final r in reminders) {
      final item = byItem[r.itemId];
      if (item == null) continue;
      if (r.snoozedUntil != null && r.snoozedUntil!.isAfter(now)) {
        final t = texts.forSnooze(item);
        add(PlannedNotification(
          notificationId: notificationIdFor(r.id, r.snoozedUntil!, snooze: true),
          reminderId: r.id,
          itemId: item.id,
          occurrenceAt: r.snoozedUntil!,
          fireAt: r.snoozedUntil!,
          title: t.title,
          body: t.body,
          isAlarm: r.isAlarm,
          kind: PlannedKind.snooze,
        ));
      }
      switch (r.triggerKind) {
        case 'absolute':
          final at = r.at;
          if (at == null) continue;
          final t = texts.forOccurrence(item, at, 0);
          add(PlannedNotification(
              notificationId: notificationIdFor(r.id, at), reminderId: r.id, itemId: item.id, occurrenceAt: at, fireAt: at,
              title: t.title, body: t.body, isAlarm: r.isAlarm));
        case 'offset':
          final off = Duration(minutes: r.offsetMinutes ?? 0);
          // Lần có giờ kêu trong cửa sổ: lần nằm trong [now + offset, end + offset] (offset âm = sau giờ đó).
          final from = off.isNegative ? now.add(off) : now;
          final to = off.isNegative ? end : end.add(off);
          for (final o in occurrences(item, from, to)) {
            if (handledOccurrences.contains((item.id, o.at.millisecondsSinceEpoch))) continue;
            final t = texts.forOccurrence(item, o.at, r.offsetMinutes ?? 0);
            add(PlannedNotification(
                notificationId: notificationIdFor(r.id, o.at), reminderId: r.id, itemId: item.id, occurrenceAt: o.at,
                fireAt: o.base.subtract(off), title: t.title, body: t.body, isAlarm: r.isAlarm, dstAdjusted: o.dstAdjusted));
          }
        default:
          continue; // location: Phase 2
      }
    }

    final sorted = out.values.toList()
      ..sort((a, b) {
        final c = a.fireAt.compareTo(b.fireAt);
        return c != 0 ? c : a.notificationId.compareTo(b.notificationId);
      });
    if (sorted.length <= maxPending) {
      return PlanResult(sorted, truncated: false, horizonEnd: end, dropped: 0);
    }
    final strict = maxPending < strictLimit;
    final keep = sorted.take(strict ? maxPending - 1 : maxPending).toList();
    if (strict) {
      final t = texts.fallback();
      final at = keep.last.fireAt.add(const Duration(minutes: 1));
      keep.add(PlannedNotification(
          notificationId: notificationIdFor('fallback', at), reminderId: 'fallback', itemId: '', occurrenceAt: at, fireAt: at,
          title: t.title, body: t.body, kind: PlannedKind.fallback));
    }
    return PlanResult(keep, truncated: true, horizonEnd: end, dropped: sorted.length - (strict ? maxPending - 1 : maxPending));
  }

  /// Các lần của [item] có giờ kêu gốc trong [from, to] (UTC). Dùng chung với màn Hôm nay ([expandOccurrences]).
  List<Occurrence> occurrences(PlannerItem item, DateTime from, DateTime to) =>
      expandOccurrences(item, from, to, deviceTz: deviceTz, allDayTime: allDayTime);

  /// ID thông báo xác định: FNV-1a 32 bit của (reminder, lần), dương 31 bit (Android dùng int32).
  static int notificationIdFor(String reminderId, DateTime occurrence, {bool snooze = false}) {
    var h = 0x811c9dc5;
    for (final c in utf8.encode('$reminderId|${snooze ? 's' : ''}${occurrence.millisecondsSinceEpoch}')) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }
}

/// Một lần của item.
class Occurrence {
  const Occurrence({required this.at, required this.base, required this.date, required this.allDay, this.dstAdjusted = false});
  /// Khóa của lần (UTC): giờ bắt đầu, hoặc 00:00 của ngày với item cả ngày. Ghi vào `occurrence_log.occurrence_at`.
  final DateTime at;
  /// Giờ kêu của nhắc "đúng giờ" (offset 0): bằng [at], hoặc giờ mặc định của item cả ngày.
  final DateTime base;
  /// Ngày tường của lần theo múi giờ của item.
  final CivilDate date;
  final bool allDay;
  final bool dstAdjusted;
}

/// Các lần của [item] có [Occurrence.base] trong [from, to] (UTC).
/// Múi giờ: `tz` của item nếu `fixed`, [deviceTz] nếu `floating` hoặc item cả ngày (reminder-engine.md §5).
List<Occurrence> expandOccurrences(PlannerItem item, DateTime from, DateTime to, {required String deviceTz, required CivilTime allDayTime}) {
  final allDay = item.allDay || item.startsAt == null;
  final zone = allDay || item.timeMode == 'floating' || item.tz == null ? deviceTz : item.tz!;
  final CivilDateTime start;
  if (!allDay) {
    if (item.recurrence == null && item.timeMode != 'floating') {
      final s = item.startsAt!;
      final o = Occurrence(at: s, base: s, date: TimeZones.toWall(s, item.tz ?? deviceTz).date, allDay: false);
      return !s.isBefore(from) && !s.isAfter(to) ? [o] : const [];
    }
    start = TimeZones.toWall(item.startsAt!, item.tz ?? deviceTz);
  } else if (item.startDate != null) {
    start = CivilDateTime(CivilDate.parse(item.startDate!));
  } else {
    return const [];
  }

  Occurrence make(CivilDateTime w) {
    if (allDay || w.time == null) {
      final at = TimeZones.toUtc(CivilDateTime(w.date, CivilTime(0)), zone);
      final base = TimeZones.toUtc(CivilDateTime(w.date, allDayTime), zone);
      return Occurrence(at: at.utc, base: base.utc, date: w.date, allDay: true, dstAdjusted: base.dstAdjusted);
    }
    final r = TimeZones.toUtc(w, zone);
    return Occurrence(at: r.utc, base: r.utc, date: w.date, allDay: false, dstAdjusted: r.dstAdjusted);
  }

  bool inRange(Occurrence o) => !o.base.isBefore(from) && !o.base.isAfter(to);
  final rec = item.recurrence;
  if (rec == null) {
    final o = make(start);
    return inRange(o) ? [o] : const [];
  }
  final fromDate = TimeZones.toWall(from, zone).date.addDays(-1);
  final toDate = TimeZones.toWall(to, zone).date.addDays(1);
  return [
    for (final w in rec.between(allDay ? CivilDateTime(start.date) : start, fromDate, toDate, exdates: item.exdates))
      if (make(w) case final o when inRange(o)) o,
  ];
}
