import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:test/test.dart';

import 'fake_server.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Ngày 1/12/2026 tính theo UTC+7: [30/11 17:00Z, 1/12 17:00Z).
  final day = DayWindow(startUtc: DateTime.utc(2026, 11, 30, 17), endUtc: DateTime.utc(2026, 12, 1, 17), localDate: '2026-12-01');

  ItemView item(String id,
          {DateTime? startsAt, String? startDate, bool allDay = false, String status = 'open', int priority = 0, DateTime? completedAt, String kind = 'task'}) =>
      ItemView(id: id, title: id, kind: kind, status: status, startsAt: startsAt, startDate: startDate, allDay: allDay,
          priority: priority, completedAt: completedAt);

  group('TodaySections.partition', () {
    test('chia quá hạn / hôm nay / chưa đặt giờ / xong hôm nay theo ranh giới ngày local', () {
      final s = TodaySections.partition([
        item('late', startsAt: DateTime.utc(2026, 11, 30, 16, 59)), // 23:59 hôm qua giờ local
        item('morning', startsAt: DateTime.utc(2026, 11, 30, 17)), // 00:00 hôm nay
        item('evening', startsAt: DateTime.utc(2026, 12, 1, 13)),
        item('tomorrow', startsAt: DateTime.utc(2026, 12, 1, 17)),
        item('allday', startDate: '2026-12-01', allDay: true),
        item('allday-old', startDate: '2026-11-29', allDay: true),
        item('someday'),
        item('urgent', priority: 3),
        item('event-no-time', kind: 'event'),
        item('done', status: 'done', completedAt: DateTime.utc(2026, 12, 1, 2)),
        item('done-yesterday', status: 'done', completedAt: DateTime.utc(2026, 11, 30, 2)),
        item('archived', status: 'archived', startsAt: DateTime.utc(2026, 12, 1, 3)),
      ], day);
      expect(s.overdue.map((i) => i.id), ['allday-old', 'late']);
      expect(s.today.map((i) => i.id), ['allday', 'morning', 'evening']);
      expect(s.noTime.map((i) => i.id), ['urgent', 'someday']);
      expect(s.doneToday.map((i) => i.id), ['done']);
    });

    test('DayWindow.ofLocal cho ngày lịch và ranh giới UTC', () {
      final w = DayWindow.ofLocal(DateTime(2026, 3, 8, 15));
      expect(w.localDate, '2026-03-08');
      expect(w.endUtc.difference(w.startUtc).inHours, inInclusiveRange(23, 25)); // ngày đổi giờ DST dài 23/25 giờ
    });
  });

  group('ItemsRepository', () {
    late AppDatabase db;
    late ItemsRepository repo;
    var wall = DateTime.utc(2026, 12, 1, 2);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      final engine = SyncEngine(
          db: db, api: FakeServer().apiFor('phone'), clock: HlcClock('phone', now: () => wall.millisecondsSinceEpoch), deviceId: 'phone');
      repo = ItemsRepository(engine, now: () => wall);
    });
    tearDown(() => db.close());

    test('tạo, hoàn thành, mở lại: stream Hôm nay cập nhật, mỗi thay đổi vào outbox', () async {
      final id = await repo.create(title: '  Gửi báo giá  ', startsAt: DateTime.utc(2026, 12, 1, 9), tz: 'Asia/Ho_Chi_Minh');
      var s = await repo.watchToday(day).first;
      expect(s.today.single.title, 'Gửi báo giá');
      expect(s.today.single.tz, 'Asia/Ho_Chi_Minh');

      wall = wall.add(const Duration(minutes: 5));
      await repo.setDone(id, done: true);
      s = await repo.watchToday(day).first;
      expect(s.today, isEmpty);
      expect(s.doneToday.single.completedAt, wall);

      await repo.setDone(id, done: false);
      s = await repo.watchToday(day).first;
      expect(s.today.single.isDone, isFalse);
      expect(s.today.single.completedAt, isNull);
      expect(await repo.engine.pendingCount(), 3);
    });

    test('đổi tên, ghi chú, ưu tiên, xóa', () async {
      final id = await repo.create(title: 'Mua quà');
      await repo.rename(id, 'Mua quà sinh nhật');
      await repo.setNotes(id, 'hoa + thiệp', baseClock: await repo.notesClock(id));
      await repo.setPriority(id, 2);
      final v = await repo.watchItem(id).first;
      expect(v!.title, 'Mua quà sinh nhật');
      expect(v.notes, 'hoa + thiệp');
      expect(v.priority, 2);
      expect(await repo.notesClock(id), isNotNull);

      await repo.delete(id);
      expect(await repo.watchItem(id).first, isNull);
      expect((await repo.watchToday(day).first).isEmpty, isTrue);
    });

    test('kiểm tra đầu vào: tiêu đề rỗng, có giờ mà thiếu tz, ưu tiên ngoài 0-3', () async {
      expect(() => repo.create(title: '   '), throwsArgumentError);
      expect(() => repo.create(title: 'x', startsAt: DateTime.utc(2026)), throwsArgumentError);
      final id = await repo.create(title: 'x');
      expect(() => repo.setPriority(id, 4), throwsRangeError);
    });

    test('việc cả ngày lưu start_date, all_day = true', () async {
      final id = await repo.create(title: 'Sinh nhật mẹ', startDate: '2026-12-01');
      final v = (await repo.watchItem(id).first)!;
      expect(v.allDay, isTrue);
      expect(v.startDate, '2026-12-01');
      expect((await repo.watchToday(day).first).today.single.id, id);
    });

    test('việc lặp: tạo hàng recurrences cùng outbox, time_mode floating; âm lịch lưu calendar', () async {
      final id = await repo.create(
          title: 'Uống thuốc', startsAt: DateTime.utc(2026, 12, 1, 13), tz: 'Asia/Ho_Chi_Minh',
          recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}, recurrenceStart: DateTime.utc(2026, 12, 1, 13));
      expect(await repo.recurrenceOf(id), containsPair('rrule', 'FREQ=DAILY'));
      expect(await repo.watchRecurringIds().first, {id});
      final row = await db.customSelect('SELECT time_mode FROM items WHERE id = ?', variables: [Variable.withString(id)]).getSingle();
      expect(row.data['time_mode'], 'floating');
      expect(await repo.engine.pendingCount(), 2);

      final lunar = await repo.create(title: 'Đi chùa', startDate: '2026-12-24',
          recurrence: {'kind': 'calendar', 'calendar': {'system': 'lunar_vi', 'day': 15}}, recurrenceStart: DateTime.utc(2026, 12, 23, 17));
      expect((await repo.recurrenceOf(lunar))!['calendar'], {'system': 'lunar_vi', 'day': 15});
      expect(() => repo.create(title: 'x', recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}), throwsArgumentError);
    });

    test('device_id sinh 1 lần cho mỗi DB (mỗi lần cài)', () async {
      final a = await InstallInfo.deviceId(db);
      expect(await InstallInfo.deviceId(db), a);
      expect(() => Hlc(0, 0, a), returnsNormally, reason: 'dùng được làm node HLC');
    });
  });
}
