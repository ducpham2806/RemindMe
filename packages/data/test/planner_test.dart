import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:test/test.dart';

class Texts implements NotificationTexts {
  @override
  ({String body, String title}) forOccurrence(PlannerItem item, DateTime occurrenceAt, int offsetMinutes) =>
      (title: item.title, body: 'at ${occurrenceAt.toIso8601String()} -$offsetMinutes');
  @override
  ({String body, String title}) forSnooze(PlannerItem item) => (title: item.title, body: 'snoozed');
  @override
  ({String body, String title}) fallback() => (title: 'Open RemindMe', body: 'to keep getting reminders');
}

void main() {
  final texts = Texts();
  PlannerReminder at0(String item, {int off = 0, String? id}) =>
      PlannerReminder(id: id ?? 'r-$item-$off', itemId: item, triggerKind: 'offset', offsetMinutes: off);

  test('việc 1 lần, giờ cố định: kêu đúng giờ và 15 phút trước; quá khứ bỏ qua', () {
    final p = ReminderPlanner(deviceTz: 'Asia/Ho_Chi_Minh', maxPending: 500);
    final now = DateTime.utc(2026, 12, 1, 3);
    final items = [
      PlannerItem(id: 'a', title: 'Meeting', startsAt: DateTime.utc(2026, 12, 1, 8), tz: 'Asia/Ho_Chi_Minh'),
      PlannerItem(id: 'old', title: 'Old', startsAt: DateTime.utc(2026, 11, 30), tz: 'Asia/Ho_Chi_Minh'),
    ];
    final r = p.plan(items: items, reminders: [at0('a'), at0('a', off: -15), at0('old')], now: now, texts: texts);
    expect(r.notifications.map((n) => n.fireAt), [DateTime.utc(2026, 12, 1, 7, 45), DateTime.utc(2026, 12, 1, 8)]);
    expect(r.truncated, isFalse);
  });

  test('offline 20 ngày: đặt ngay nhắc đơn, nhắc tuyệt đối và hoãn; chuỗi lặp vẫn giới hạn 14 ngày', () {
    final now = DateTime.utc(2026, 12, 1);
    final far = now.add(const Duration(days: 20));
    final plan = ReminderPlanner(deviceTz: 'Etc/UTC', maxPending: 60).plan(
      items: [
        PlannerItem(id: 'visit', title: 'Visit', startsAt: far),
        PlannerItem(id: 'weekly', title: 'Weekly', startsAt: far, recurrence: RRuleRecurrence('FREQ=WEEKLY')),
      ],
      reminders: [
        at0('visit', off: -15), at0('weekly'),
        PlannerReminder(id: 'absolute', itemId: 'visit', triggerKind: 'absolute', at: far, snoozedUntil: far.add(const Duration(hours: 1))),
      ],
      now: now, texts: texts,
    );
    expect(plan.notifications.map((n) => n.fireAt), [far.subtract(const Duration(minutes: 15)), far, far.add(const Duration(hours: 1))]);
    expect(plan.truncated, isFalse);
  });

  test('khi ít chỗ, nhắc gần được ưu tiên trước nhắc xa', () {
    final now = DateTime.utc(2026, 12, 1);
    final items = [for (final days in [30, 20, 1]) PlannerItem(id: '$days', title: 'Visit', startsAt: now.add(Duration(days: days)))];
    for (final limit in [0, 1, 2]) {
      final plan = ReminderPlanner(deviceTz: 'Etc/UTC', maxPending: limit).plan(
        items: items, reminders: [for (final item in items) at0(item.id)], now: now, texts: texts,
      );
      expect(plan.notifications.length, limit);
      if (limit > 0) expect(plan.notifications.first.itemId, '1');
      if (limit == 2) expect(plan.notifications.last.kind, PlannedKind.fallback);
    }
  });

  test('giờ yên lặng 22:00–07:00 (qua nửa đêm, theo giờ máy): nhắc vẫn lập nhưng im lặng; báo thức vẫn kêu; đổi khung đổi contentHash', () {
    final q = QuietHours(CivilTime(22), CivilTime(7));
    expect([for (final h in [21, 22, 23, 0, 6, 7]) q.covers(CivilTime(h))], [false, true, true, true, true, false]);
    expect(QuietHours(CivilTime(13), CivilTime(14)).covers(CivilTime(13, 30)), isTrue);
    expect(QuietHours(CivilTime(8), CivilTime(8)).covers(CivilTime(8)), isFalse, reason: 'bắt đầu = kết thúc là tắt');
    expect(QuietHours.parse('22:00-07:00')!.encode(), '22:00-07:00');
    expect(QuietHours.parse('x'), isNull);

    const tz = 'Asia/Ho_Chi_Minh';
    final now = DateTime.utc(2026, 12, 1, 3);
    final items = [
      PlannerItem(id: 'late', title: 'Late', startsAt: DateTime.utc(2026, 12, 1, 16, 30), tz: tz), // 23:30 VN
      PlannerItem(id: 'day', title: 'Day', startsAt: DateTime.utc(2026, 12, 1, 8), tz: tz), // 15:00 VN
      PlannerItem(id: 'wake', title: 'Wake', startsAt: DateTime.utc(2026, 12, 1, 22), tz: tz), // 05:00 VN, kiểu báo thức
    ];
    final reminders = [at0('late'), at0('day'), PlannerReminder(id: 'r-wake', itemId: 'wake', triggerKind: 'offset', offsetMinutes: 0, isAlarm: true)];
    final quiet = ReminderPlanner(deviceTz: tz, maxPending: 500, quietHours: q).plan(items: items, reminders: reminders, now: now, texts: texts);
    expect({for (final n in quiet.notifications) n.itemId: n.silent}, {'day': false, 'late': true, 'wake': false});
    final loud = ReminderPlanner(deviceTz: tz, maxPending: 500).plan(items: items, reminders: reminders, now: now, texts: texts);
    final late = (quiet.notifications.firstWhere((n) => n.itemId == 'late'), loud.notifications.firstWhere((n) => n.itemId == 'late'));
    expect(late.$1.fireAt, late.$2.fireAt, reason: 'không dời giờ');
    expect(late.$1.contentHash, isNot(late.$2.contentHash), reason: 'bật/tắt giờ yên lặng thì lập lại thông báo đó');
  });

  test('lặp hằng ngày 08:00 floating qua ngày DST New York: vẫn 08:00 giờ tường', () {
    final p = ReminderPlanner(deviceTz: 'America/New_York', maxPending: 500, horizon: const Duration(days: 3));
    final item = PlannerItem(
      id: 'pill', title: 'Pills', kind: 'habit', timeMode: 'floating', tz: 'America/New_York',
      startsAt: DateTime.utc(2026, 3, 1, 13), // 08:00 EST
      recurrence: RRuleRecurrence('FREQ=DAILY'),
    );
    final r = p.plan(items: [item], reminders: [at0('pill')], now: DateTime.utc(2026, 3, 7, 0), texts: texts);
    expect(r.notifications.map((n) => TimeZones.toWall(n.fireAt, 'America/New_York').time), everyElement(CivilTime(8)));
    // 7/3 EST (13:00Z), 8/3 và 9/3 EDT (12:00Z): khoảng cách 23 giờ qua ngày đổi giờ.
    expect(r.notifications.map((n) => n.fireAt.hour), [13, 12, 12]);
  });

  test('floating đi du lịch: 08:00 theo nơi đang đứng; fixed giữ giờ của tz sự kiện', () {
    final floating = PlannerItem(id: 'f', title: 'Run', timeMode: 'floating', tz: 'Asia/Ho_Chi_Minh',
        startsAt: DateTime.utc(2026, 12, 1, 1), recurrence: RRuleRecurrence('FREQ=DAILY'));
    final fixed = PlannerItem(id: 'x', title: 'Call', tz: 'Asia/Ho_Chi_Minh', startsAt: DateTime.utc(2026, 12, 3, 1));
    final p = ReminderPlanner(deviceTz: 'Europe/London', maxPending: 500, horizon: const Duration(days: 2));
    final r = p.plan(items: [floating, fixed], reminders: [at0('f'), at0('x')], now: DateTime.utc(2026, 12, 2), texts: texts);
    final runs = r.notifications.where((n) => n.itemId == 'f');
    expect(runs.map((n) => TimeZones.toWall(n.fireAt, 'Europe/London').time), everyElement(CivilTime(8)));
    expect(r.notifications.firstWhere((n) => n.itemId == 'x').fireAt, DateTime.utc(2026, 12, 3, 1));
  });

  test('giờ không tồn tại (02:30 ngày 8/3 New York) kêu 03:00, đánh dấu dstAdjusted', () {
    final p = ReminderPlanner(deviceTz: 'America/New_York', maxPending: 500, horizon: const Duration(days: 2));
    final item = PlannerItem(id: 'n', title: 'Night', tz: 'America/New_York', startsAt: DateTime.utc(2026, 3, 5, 7, 30),
        recurrence: RRuleRecurrence('FREQ=DAILY'));
    final r = p.plan(items: [item], reminders: [at0('n')], now: DateTime.utc(2026, 3, 7, 12), texts: texts);
    final [n, next] = r.notifications;
    expect(TimeZones.toWall(n.fireAt, 'America/New_York'), CivilDateTime(CivilDate(2026, 3, 8), CivilTime(3)));
    expect(n.dstAdjusted, isTrue);
    expect(TimeZones.toWall(next.fireAt, 'America/New_York').time, CivilTime(2, 30));
    expect(next.dstAdjusted, isFalse);
  });

  test('item cả ngày kêu lúc giờ mặc định theo nơi đang đứng; âm lịch rằm', () {
    final p = ReminderPlanner(deviceTz: 'Asia/Ho_Chi_Minh', maxPending: 500, horizon: const Duration(days: 40));
    final items = [
      const PlannerItem(id: 'bday', title: 'Birthday', startDate: '2026-12-05', allDay: true),
      PlannerItem(id: 'ram', title: 'Temple', startDate: '2026-12-23', allDay: true,
          recurrence: LunarRecurrence(LunarSystem.vi, day: 15)),
    ];
    final r = p.plan(items: items, reminders: [at0('bday'), at0('ram')], now: DateTime.utc(2026, 12, 1), texts: texts);
    expect(r.notifications.map((n) => '${n.itemId} ${TimeZones.toWall(n.fireAt, 'Asia/Ho_Chi_Minh')}'),
        ['bday 2026-12-05 09:00', 'ram 2026-12-23 09:00']);
  });

  test('lần đã Xong (occurrence_log) không kêu; hoãn thêm 1 thông báo', () {
    final p = ReminderPlanner(deviceTz: 'Etc/UTC', maxPending: 500, horizon: const Duration(days: 3));
    final item = PlannerItem(id: 'd', title: 'Daily', tz: 'Etc/UTC', startsAt: DateTime.utc(2026, 12, 1, 9),
        recurrence: RRuleRecurrence('FREQ=DAILY'));
    final now = DateTime.utc(2026, 12, 1, 8);
    final r = p.plan(
      items: [item],
      reminders: [PlannerReminder(id: 'r', itemId: 'd', triggerKind: 'offset', offsetMinutes: 0, snoozedUntil: DateTime.utc(2026, 12, 1, 8, 10))],
      handledOccurrences: {('d', DateTime.utc(2026, 12, 1, 9).millisecondsSinceEpoch)},
      now: now,
      texts: texts,
    );
    expect(r.notifications.map((n) => '${n.kind.name} ${n.fireAt.toIso8601String()}'), [
      'snooze 2026-12-01T08:10:00.000Z',
      'occurrence 2026-12-02T09:00:00.000Z',
      'occurrence 2026-12-03T09:00:00.000Z',
    ]);
  });

  test('iOS: quá 60 thì giữ 59 lần gần nhất + 1 thông báo dự phòng; Android không chừa', () {
    final item = PlannerItem(id: 'h', title: 'Water', tz: 'Etc/UTC', startsAt: DateTime.utc(2026, 12, 1),
        recurrence: RRuleRecurrence('FREQ=HOURLY'));
    final now = DateTime.utc(2026, 12, 1, 0, 30);
    final ios = ReminderPlanner(deviceTz: 'Etc/UTC', maxPending: 60).plan(items: [item], reminders: [at0('h')], now: now, texts: texts);
    expect(ios.notifications, hasLength(60));
    expect(ios.truncated, isTrue);
    expect(ios.notifications.last.kind, PlannedKind.fallback);
    expect(ios.notifications.last.fireAt, ios.notifications[58].fireAt.add(const Duration(minutes: 1)));
    final android = ReminderPlanner(deviceTz: 'Etc/UTC', maxPending: 500).plan(items: [item], reminders: [at0('h')], now: now, texts: texts);
    expect(android.notifications.every((n) => n.kind == PlannedKind.occurrence), isTrue);
    expect(android.notifications, hasLength(336)); // 14 ngày × 24
  });

  test('ID xác định, ổn định giữa các lần lập lịch, trong int32 dương', () {
    final a = ReminderPlanner.notificationIdFor('r1', DateTime.utc(2026, 12, 1, 9));
    expect(ReminderPlanner.notificationIdFor('r1', DateTime.utc(2026, 12, 1, 9)), a);
    expect(ReminderPlanner.notificationIdFor('r1', DateTime.utc(2026, 12, 2, 9)), isNot(a));
    expect(a, inInclusiveRange(0, 0x7fffffff));
  });
}
