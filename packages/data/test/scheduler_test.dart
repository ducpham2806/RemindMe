import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_platform/remindme_platform.dart';
import 'package:test/test.dart';

import 'fake_server.dart';
import 'planner_test.dart' show Texts;

class FakeOs implements NotificationScheduler {
  final pending = <int, ScheduledNotification>{};
  int scheduledCalls = 0, cancelledCalls = 0;
  @override
  int get maxPending => 500;
  @override
  Future<void> schedule(List<ScheduledNotification> n) async {
    scheduledCalls += n.length;
    for (final x in n) {
      pending[x.notificationId] = x;
    }
  }

  @override
  Future<void> cancel(Iterable<int> ids) async {
    cancelledCalls += ids.length;
    ids.forEach(pending.remove);
  }

  @override
  Future<void> cancelAll() async => pending.clear();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ItemsRepository repo;
  late FakeOs os;
  final now = DateTime.utc(2026, 12, 1, 1);

  ReminderScheduler scheduler({String locale = 'en'}) => ReminderScheduler(
      db: db, os: os, planner: ReminderPlanner(deviceTz: 'Asia/Ho_Chi_Minh', maxPending: os.maxPending), texts: Texts(),
      locale: locale, now: () => now);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    os = FakeOs();
    final engine = SyncEngine(db: db, api: FakeServer().apiFor('p'), clock: HlcClock('p', now: () => now.millisecondsSinceEpoch), deviceId: 'p');
    repo = ItemsRepository(engine, now: () => now);
  });
  tearDown(() => db.close());

  test('lập lịch, chạy lại không đổi gì, sửa tiêu đề lập lại đúng 1, xóa item thì hủy', () async {
    final a = await repo.create(title: 'Meeting', startsAt: DateTime.utc(2026, 12, 1, 8), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0, 15]);
    await repo.create(title: 'Daily', startsAt: DateTime.utc(2026, 12, 1, 2), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0],
        recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}, recurrenceStart: DateTime.utc(2026, 12, 1, 2));
    var r = await scheduler().reschedule();
    expect(r.total, 2 + 14);
    expect(os.pending, hasLength(16));

    r = await scheduler().reschedule();
    expect((r.scheduled, r.cancelled), (0, 0));

    await repo.rename(a, 'Client meeting');
    r = await scheduler().reschedule();
    expect((r.scheduled, r.cancelled), (2, 2));
    expect(os.pending.values.where((n) => n.title == 'Client meeting'), hasLength(2));

    await repo.delete(a);
    r = await scheduler().reschedule();
    expect(r.cancelled, 2);
    expect(os.pending, hasLength(14));
    expect(await db.select(db.scheduledNotifications).get(), hasLength(14));
  });

  test('xong 1 lần của chuỗi lặp → hủy đúng lần đó; xong việc 1 lần → hủy hết nhắc của nó', () async {
    final d = await repo.create(title: 'Daily', startsAt: DateTime.utc(2026, 12, 1, 2), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0],
        recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}, recurrenceStart: DateTime.utc(2026, 12, 1, 2));
    final once = await repo.create(title: 'Once', startsAt: DateTime.utc(2026, 12, 3, 2), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0]);
    await scheduler().reschedule();
    expect(os.pending, hasLength(15));
    await repo.completeOccurrence(d, DateTime.utc(2026, 12, 2, 2));
    await repo.setDone(once, done: true);
    final r = await scheduler().reschedule();
    expect(r.cancelled, 2);
    expect(os.pending.values.map((n) => n.fireAtUtc), isNot(contains(DateTime.utc(2026, 12, 2, 2))));
  });

  test('đổi ngôn ngữ app → lập lại tất cả; bị đăng xuất → hủy hết', () async {
    await repo.create(title: 'Meeting', startsAt: DateTime.utc(2026, 12, 1, 8), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0]);
    await scheduler().reschedule();
    final r = await scheduler(locale: 'vi').reschedule();
    expect((r.scheduled, r.cancelled), (1, 1));
    await scheduler().cancelAll();
    expect(os.pending, isEmpty);
    expect(await db.select(db.scheduledNotifications).get(), isEmpty);
  });

  test('hoãn: snoozed_until thêm 1 thông báo, payload có item + lần, không có nội dung', () async {
    final a = await repo.create(title: 'Meeting', startsAt: DateTime.utc(2026, 12, 1, 8), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0]);
    final rid = (await repo.remindersOf(a)).single.id;
    await repo.snooze(rid, until: DateTime.utc(2026, 12, 1, 1, 10));
    await scheduler().reschedule();
    final snooze = os.pending.values.firstWhere((n) => n.fireAtUtc == DateTime.utc(2026, 12, 1, 1, 10));
    expect(snooze.payload, contains(a));
    expect(snooze.payload, isNot(contains('Meeting')));
  });
}
