import 'dart:io';

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
      var s = await repo.watchToday(day, deviceTz: 'Asia/Ho_Chi_Minh').first;
      expect(s.today.single.title, 'Gửi báo giá');
      expect(s.today.single.tz, 'Asia/Ho_Chi_Minh');

      wall = wall.add(const Duration(minutes: 5));
      await repo.setDone(id, done: true);
      s = await repo.watchToday(day, deviceTz: 'Asia/Ho_Chi_Minh').first;
      expect(s.today, isEmpty);
      expect(s.doneToday.single.completedAt, wall);

      await repo.setDone(id, done: false);
      s = await repo.watchToday(day, deviceTz: 'Asia/Ho_Chi_Minh').first;
      expect(s.today.single.isDone, isFalse);
      expect(s.today.single.completedAt, isNull);
      expect(await repo.engine.pendingCount(), 3);
    });

    test('countsByDay: item có giờ theo ngày ở múi giờ máy, cả ngày theo ngày, chuỗi lặp trải từng lần, bỏ đã xóa và lần bỏ qua', () async {
      const tz = 'Asia/Ho_Chi_Minh';
      await repo.create(title: 'late night', startsAt: DateTime.utc(2026, 12, 1, 18), tz: tz); // 01:00 ngày 2/12 giờ VN
      await repo.create(title: 'all day', startDate: '2026-12-02');
      await repo.create(title: 'outside', startDate: '2026-12-09');
      final gone = await repo.create(title: 'gone', startDate: '2026-12-03');
      await repo.delete(gone);
      final daily = await repo.create(title: 'pills', startsAt: DateTime.utc(2026, 12, 1, 1), tz: tz,
          recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}, recurrenceStart: DateTime.utc(2026, 12, 1, 1));
      await repo.skipOccurrence(daily, DateTime.utc(2026, 12, 3, 1));
      final counts = await repo.countsByDay(CivilDate(2026, 12, 1), CivilDate(2026, 12, 4), deviceTz: tz);
      expect(counts, {'2026-12-01': 1, '2026-12-02': 3, '2026-12-04': 1});
    });

    test('lặp ngày làm việc của VN: Hôm nay không có lần vào ngày nghỉ lễ 30/4, có lại 4/5', () async {
      HolidayCalendars.register(HolidayCalendar.parse(File('../core/data/holidays/VN.json').readAsStringSync()));
      addTearDown(HolidayCalendars.clear);
      const tz = 'Asia/Ho_Chi_Minh';
      final id = await repo.create(title: 'Chấm công', startsAt: DateTime.utc(2026, 4, 1, 1), tz: tz,
          recurrence: {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR', 'workdays_region': 'VN'},
          recurrenceStart: DateTime.utc(2026, 4, 1, 1));
      DayWindow vnDay(int m, int d) => DayWindow(
          startUtc: DateTime.utc(2026, m, d).subtract(const Duration(hours: 7)), endUtc: DateTime.utc(2026, m, d + 1).subtract(const Duration(hours: 7)),
          localDate: DayWindow.isoDate(DateTime.utc(2026, m, d)));
      expect((await repo.watchToday(vnDay(4, 29), deviceTz: tz).first).today.map((i) => i.id), [id]);
      expect((await repo.watchToday(vnDay(4, 30), deviceTz: tz).first).today, isEmpty);
      expect((await repo.watchToday(vnDay(5, 4), deviceTz: tz).first).today.map((i) => i.id), [id]);
      expect((await repo.recurrenceOf(id))!['workdays_region'], 'VN');
    });

    test('openTasksOn + moveToDate: chỉ việc 1 lần đang mở; dời giữ giờ tường, việc cả ngày đổi ngày', () async {
      const tz = 'Asia/Ho_Chi_Minh';
      final timed = await repo.create(title: 'Báo cáo', startsAt: DateTime.utc(2026, 4, 30, 2), tz: tz); // 9:00 30/4
      final allDay = await repo.create(title: 'Nộp thuế', startDate: '2026-04-30');
      await repo.create(title: 'Họp', kind: 'event', startsAt: DateTime.utc(2026, 4, 30, 3), tz: tz);
      await repo.create(title: 'Uống thuốc', startsAt: DateTime.utc(2026, 4, 30, 1), tz: tz,
          recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}, recurrenceStart: DateTime.utc(2026, 4, 30, 1));
      await repo.create(title: 'Late', startsAt: DateTime.utc(2026, 4, 30, 18), tz: tz); // 1:00 ngày 1/5 giờ VN
      final hits = await repo.openTasksOn({'2026-04-30'}, deviceTz: tz);
      expect(hits.map((i) => i.title).toSet(), {'Báo cáo', 'Nộp thuế'});
      for (final i in hits) {
        await repo.moveToDate(i, CivilDate(2026, 5, 4), deviceTz: tz);
      }
      expect((await repo.getItem(timed))!.startsAt, DateTime.utc(2026, 5, 4, 2));
      expect((await repo.getItem(allDay))!.startDate, '2026-05-04');
      expect(await repo.openTasksOn({'2026-04-30'}, deviceTz: tz), isEmpty);
    });

    test('LocalPrefs: tập giá trị chỉ ở máy này', () async {
      final prefs = LocalPrefs(db);
      expect(await prefs.getSet('x'), isEmpty);
      await prefs.addToSet('x', 'b');
      await prefs.addToSet('x', 'a');
      await prefs.addToSet('x', 'a');
      expect(await prefs.getSet('x'), {'a', 'b'});
      expect(await repo.engine.pendingCount(), 0, reason: 'không vào outbox');
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
      expect((await repo.watchToday(day, deviceTz: 'Asia/Ho_Chi_Minh').first).isEmpty, isTrue);
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
      expect((await repo.watchToday(day, deviceTz: 'Asia/Ho_Chi_Minh').first).today.single.id, id);
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

    test('Hôm nay trải từng lần của chuỗi lặp; Xong 1 lần chỉ đóng lần đó; hoàn tác mở lại', () async {
      // 07:00 và 19:00 giờ VN mỗi ngày (FREQ=DAILY;BYHOUR=7,19), bắt đầu từ hôm qua.
      final id = await repo.create(title: 'Pills', startsAt: DateTime.utc(2026, 11, 30), tz: 'Asia/Ho_Chi_Minh',
          recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY;BYHOUR=7,19;BYMINUTE=0'}, recurrenceStart: DateTime.utc(2026, 11, 30));
      final ram = await repo.create(title: 'Temple', startDate: '2026-11-24',
          recurrence: {'kind': 'calendar', 'calendar': {'system': 'lunar_vi', 'day': 15}}, recurrenceStart: DateTime.utc(2026, 11, 23, 17));
      // Ngày 23/12/2026 là rằm tháng 11 âm.
      final dec23 = DayWindow(startUtc: DateTime.utc(2026, 12, 22, 17), endUtc: DateTime.utc(2026, 12, 23, 17), localDate: '2026-12-23');
      final s = await repo.watchToday(dec23, deviceTz: 'Asia/Ho_Chi_Minh').first;
      expect(s.today.map((i) => (i.title, i.startsAt?.hour)), [('Temple', null), ('Pills', 0), ('Pills', 12)]);
      expect(s.overdue, isEmpty, reason: 'lần lặp đã qua không dồn vào Quá hạn');

      var t = await repo.watchToday(day, deviceTz: 'Asia/Ho_Chi_Minh').first;
      expect(t.today.where((i) => i.isOccurrence).map((i) => i.rowKey).toSet(), hasLength(2));
      final morning = t.today.firstWhere((i) => i.title == 'Pills');
      await repo.completeOccurrence(id, morning.occurrenceAt!);
      t = await repo.watchToday(day, deviceTz: 'Asia/Ho_Chi_Minh').first;
      expect(t.today.where((i) => i.title == 'Pills'), hasLength(1));
      expect(t.doneToday.single.occurrenceAt, morning.occurrenceAt);
      await repo.reopenOccurrence(id, morning.occurrenceAt!);
      t = await repo.watchToday(day, deviceTz: 'Asia/Ho_Chi_Minh').first;
      expect(t.today.where((i) => i.title == 'Pills'), hasLength(2));
      expect(ram, isNotEmpty);
    });

    test('đổi thời điểm: có giờ ↔ cả ngày ↔ bỏ ngày; đặt và bỏ lặp', () async {
      final id = await repo.create(title: 'Gym');
      await repo.setSchedule(id, startsAt: DateTime.utc(2026, 12, 1, 11), tz: 'Asia/Ho_Chi_Minh');
      var v = (await repo.watchItem(id).first)!;
      expect((v.startsAt, v.allDay, v.startDate), (DateTime.utc(2026, 12, 1, 11), false, null));
      await repo.setSchedule(id, startDate: '2026-12-02', tz: 'Asia/Ho_Chi_Minh');
      v = (await repo.watchItem(id).first)!;
      expect((v.startsAt, v.allDay, v.startDate), (null, true, '2026-12-02'));
      await repo.setRecurrence(id, {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=WE'}, start: DateTime.utc(2026, 12, 1, 17));
      expect(await repo.isRecurring(id), isTrue);
      await repo.setRecurrence(id, null);
      expect(await repo.isRecurring(id), isFalse);
      await repo.setSchedule(id);
      v = (await repo.watchItem(id).first)!;
      expect(v.isScheduled, isFalse);
      expect(() => repo.setSchedule(id, startsAt: DateTime.utc(2026)), throwsArgumentError);
    });

    test('tìm kiếm không dấu trên tiêu đề, ghi chú, tag; việc mở trước', () async {
      final a = await repo.create(title: 'Khám răng ở Đà Lạt', tags: ['sức khỏe']);
      final b = await repo.create(title: 'Mua vé', notes: 'đi Đà Lạt cuối tuần');
      await repo.setDone(a, done: true);
      await repo.create(title: 'Gọi mẹ');
      expect((await repo.search('da lat')).map((i) => i.id), [b, a]);
      expect((await repo.search('SUC KHOE')).single.id, a);
      expect(await repo.search('   '), isEmpty);
      expect(await repo.search('da lat me'), isEmpty, reason: 'mọi từ phải khớp');
    });

    test('device_id sinh 1 lần cho mỗi DB (mỗi lần cài)', () async {
      final a = await InstallInfo.deviceId(db);
      expect(await InstallInfo.deviceId(db), a);
      expect(() => Hlc(0, 0, a), returnsNormally, reason: 'dùng được làm node HLC');
    });
  });
}
