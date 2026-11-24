import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_platform/testing.dart';
import 'package:test/test.dart';

import 'fake_server.dart';
import 'planner_test.dart' show Texts;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ItemsRepository repo;
  late InMemoryNotificationScheduler os;
  final now = DateTime.utc(2026, 12, 1, 1);

  ReminderScheduler scheduler({String locale = 'en'}) => ReminderScheduler(
      db: db, os: os, planner: ReminderPlanner(deviceTz: 'Asia/Ho_Chi_Minh', maxPending: os.maxPending), texts: Texts(),
      locale: locale, now: () => now);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    os = InMemoryNotificationScheduler();
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

  test('nút trên thông báo: Xong 1 lần của chuỗi, Xong việc 1 lần, Hoãn 10 phút; payload hỏng thì bỏ qua', () async {
    final d = await repo.create(title: 'Daily', startsAt: DateTime.utc(2026, 12, 1, 2), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0],
        recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}, recurrenceStart: DateTime.utc(2026, 12, 1, 2));
    final once = await repo.create(title: 'Once', startsAt: DateTime.utc(2026, 12, 3, 2), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0]);
    await scheduler().reschedule();
    final h = NotificationActionHandler(repo, now: () => now);
    String payloadFor(String item) => os.pending.values.firstWhere((n) => n.payload!.contains(item)).payload!;

    expect(await h.handle(NotificationActionIds.done, payloadFor(d)), isTrue);
    expect(await h.handle(NotificationActionIds.done, payloadFor(once)), isTrue);
    expect((await repo.watchItem(once).first)!.isDone, isTrue);
    expect((await repo.watchItem(d).first)!.isDone, isFalse, reason: 'chuỗi lặp vẫn mở');

    final r = await scheduler().reschedule();
    expect(r.total, 13, reason: '14 lần − lần đã Xong');
    final rid = (await repo.remindersOf(d)).single.id;
    expect(await h.handle(NotificationActionIds.snooze10, os.pending.values.first.payload), isTrue);
    expect((await repo.remindersOf(d)).single.snoozedUntil, now.add(const Duration(minutes: 10)).millisecondsSinceEpoch);
    expect(rid, isNotEmpty);
    expect(await h.handle(NotificationActionIds.done, 'not json'), isFalse);
    expect(await h.handle(null, payloadFor(d)), isFalse);
  });
}
