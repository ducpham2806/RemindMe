import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_platform/remindme_platform.dart';

import '../database.dart';
import 'planner.dart';

class ScheduleReport {
  const ScheduleReport({required this.total, required this.scheduled, required this.cancelled, required this.truncated, required this.horizonEnd});
  final int total;
  final int scheduled;
  final int cancelled;
  final bool truncated;
  final DateTime horizonEnd;
  @override
  String toString() => 'ScheduleReport(total $total, +$scheduled, -$cancelled, truncated $truncated)';
}

/// `reschedule()` của reminder-engine.md §1: đọc DB local → [ReminderPlanner] → diff với `scheduled_notifications` → OS.
/// Gọi khi mở app, sau mỗi thay đổi item/reminder/recurrence, sau sync pull, khi đổi ngôn ngữ/12-24h/múi giờ.
class ReminderScheduler {
  ReminderScheduler({required this.db, required this.os, required this.planner, required this.texts, required this.locale, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase db;
  final NotificationScheduler os;
  final ReminderPlanner planner;
  final NotificationTexts texts;
  /// Ngôn ngữ của chuỗi trong thông báo đã lập lịch: đổi ngôn ngữ thì lập lại tất cả.
  final String locale;
  final DateTime Function() _now;

  Future<ScheduleReport> reschedule() async {
    final now = _now().toUtc();
    final (items, reminders, handled) = await _load();
    final plan = planner.plan(items: items, reminders: reminders, now: now, texts: texts, handledOccurrences: handled);

    final existing = {for (final r in await db.select(db.scheduledNotifications).get()) r.notificationId: r};
    final wanted = {for (final n in plan.notifications) n.notificationId: n};
    bool same(ScheduledNotificationRow e, PlannedNotification n) => e.contentHash == n.contentHash && e.locale == locale;
    final toCancel = <int>[
      for (final e in existing.values)
        if (wanted[e.notificationId] == null || !same(e, wanted[e.notificationId]!)) e.notificationId,
    ];
    final toSchedule = <PlannedNotification>[
      for (final n in plan.notifications)
        if (existing[n.notificationId] == null || !same(existing[n.notificationId]!, n)) n,
    ];

    if (toCancel.isNotEmpty) await os.cancel(toCancel);
    if (toSchedule.isNotEmpty) {
      await os.schedule([
        for (final n in toSchedule)
          ScheduledNotification(
            notificationId: n.notificationId,
            reminderId: n.reminderId,
            fireAtUtc: n.fireAt,
            title: n.title,
            body: n.body,
            isAlarm: n.isAlarm,
            payload: n.kind == PlannedKind.fallback ? null : n.payload,
          ),
      ]);
    }
    await db.transaction(() async {
      if (toCancel.isNotEmpty) {
        await (db.delete(db.scheduledNotifications)..where((t) => t.notificationId.isIn(toCancel))).go();
      }
      for (final n in toSchedule) {
        await db.into(db.scheduledNotifications).insertOnConflictUpdate(ScheduledNotificationsCompanion.insert(
              notificationId: Value(n.notificationId),
              reminderId: n.reminderId,
              itemId: n.itemId,
              occurrenceAt: n.occurrenceAt.millisecondsSinceEpoch,
              fireAt: n.fireAt.millisecondsSinceEpoch,
              contentHash: n.contentHash,
              locale: locale,
            ));
      }
    });
    return ScheduleReport(
        total: plan.notifications.length, scheduled: toSchedule.length, cancelled: toCancel.length,
        truncated: plan.truncated, horizonEnd: plan.horizonEnd);
  }

  /// Bị đăng xuất (session_revoked) hoặc đổi tài khoản: hủy hết (reminder-engine.md §8).
  Future<void> cancelAll() async {
    await os.cancelAll();
    await db.delete(db.scheduledNotifications).go();
  }

  Future<(List<PlannerItem>, List<PlannerReminder>, Set<(String, int)>)> _load() async {
    final itemRows = await (db.select(db.items)
          ..where((t) => t.deletedAt.isNull() & t.status.isIn(const ['open', 'pending_quota'])))
        .get();
    final recRows = {
      for (final r in await (db.select(db.recurrences)..where((t) => t.deletedAt.isNull())).get()) r.itemId: r,
    };
    final items = [for (final i in itemRows) plannerItemOf(i, recRows[i.id], deviceTz: planner.deviceTz)];
    final ids = {for (final i in items) i.id};
    final reminders = [
      for (final r in await (db.select(db.reminders)..where((t) => t.deletedAt.isNull())).get())
        if (ids.contains(r.itemId))
          PlannerReminder(
            id: r.id,
            itemId: r.itemId!,
            triggerKind: r.triggerKind ?? 'offset',
            at: r.at == null ? null : DateTime.fromMillisecondsSinceEpoch(r.at!, isUtc: true),
            offsetMinutes: r.offsetMinutes,
            isAlarm: r.isAlarm ?? false,
            snoozedUntil: r.snoozedUntil == null ? null : DateTime.fromMillisecondsSinceEpoch(r.snoozedUntil!, isUtc: true),
          ),
    ];
    final handled = {
      for (final o in await (db.select(db.occurrenceLog)
            ..where((t) => t.deletedAt.isNull() & t.status.isIn(const ['done', 'skipped'])))
          .get())
        (o.itemId, o.occurrenceAt),
    };
    return (items, reminders, handled);
  }

}

/// Hàng `items` (+ `recurrences`) của DB local → [PlannerItem]. Dùng chung cho lập lịch nhắc và màn Hôm nay.
PlannerItem plannerItemOf(Item i, RecurrenceRow? rec, {required String deviceTz}) {
  Recurrence? recurrence;
  if (rec != null) {
    try {
      recurrence = Recurrence.fromRow({
        'kind': rec.kind,
        'rrule': rec.rrule,
        'calendar': rec.calendar == null ? null : jsonDecode(rec.calendar!),
        'interval_days': rec.intervalDays,
      });
    } on Object {
      recurrence = null; // quy tắc hỏng/chưa hỗ trợ (hijri ở Phase 2): coi như không lặp
    }
  }
  final zone = i.timeMode == 'floating' || i.tz == null ? deviceTz : i.tz!;
  return PlannerItem(
    id: i.id,
    title: i.title ?? '',
    kind: i.kind ?? 'task',
    startsAt: i.startsAt == null ? null : DateTime.fromMillisecondsSinceEpoch(i.startsAt!, isUtc: true),
    startDate: i.startDate,
    allDay: i.allDay ?? false,
    tz: i.tz,
    timeMode: i.timeMode ?? 'fixed',
    recurrence: recurrence,
    exdates: {for (final x in _exdates(rec?.exdates)) TimeZones.toWall(x, zone)},
  );
}

/// `recurrences.exdates` (timestamptz[] lưu JSON): ISO 8601 hoặc epoch ms.
List<DateTime> _exdates(String? json) {
  if (json == null) return const [];
  return [
    for (final v in jsonDecode(json) as List<Object?>)
      if (v is String) DateTime.parse(v).toUtc() else if (v is int) DateTime.fromMillisecondsSinceEpoch(v, isUtc: true),
  ];
}
