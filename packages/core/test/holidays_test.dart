import 'dart:io';

import 'package:remindme_core/remindme_core.dart';
import 'package:test/test.dart';

HolidayCalendar pack(String region) => HolidayCalendar.parse(File('data/holidays/$region.json').readAsStringSync());

List<String> days(HolidayCalendar c, int year, {bool dayOffOnly = true}) =>
    [for (final h in c.inYear(year)) if (!dayOffOnly || h.dayOff) '${h.date.toIso()} ${h.id}${h.substitute ? '*' : ''}'];

void main() {
  test('Phục sinh theo lịch Gregory', () {
    expect([for (final y in [2024, 2025, 2026, 2038]) easterSunday(y).toIso()], ['2024-03-31', '2025-04-20', '2026-04-05', '2038-04-25']);
  });

  test('VN: giao thừa, Tết, Giỗ Tổ theo âm lịch UTC+7; năm có tháng 2 nhuận (2023)', () {
    final vn = pack('VN');
    expect(days(vn, 2025), [
      '2025-01-01 new_year', '2025-01-28 tet_eve', '2025-01-29 tet', '2025-01-30 tet', '2025-01-31 tet',
      '2025-04-07 hung_kings', '2025-04-30 reunification', '2025-05-01 labour', '2025-09-02 national_day',
    ]);
    expect(vn.on(CivilDate(2026, 2, 17)).single.name('vi'), 'Tết Nguyên đán');
    expect(vn.on(CivilDate(2026, 4, 26)).single.id, 'hung_kings');
    expect(vn.on(CivilDate(2023, 4, 29)).single.id, 'hung_kings', reason: 'tháng 3 âm sau tháng 2 nhuận');
    expect(vn.on(CivilDate(2025, 10, 6)).single.dayOff, isFalse, reason: 'Trung thu chỉ để hiển thị');
    expect(vn.isDayOff(CivilDate(2025, 10, 6)), isFalse);
    expect(vn.isDayOff(CivilDate(2025, 1, 28)), isTrue);
  });

  test('US: thứ N trong tháng, thứ Hai cuối tháng, ngày bù T7 → T6 và CN → T2, kể cả sang năm trước', () {
    final us = pack('US');
    expect(days(us, 2026), [
      '2026-01-01 new_year', '2026-01-19 mlk_day', '2026-02-16 washingtons_birthday', '2026-05-25 memorial_day',
      '2026-06-19 juneteenth', '2026-07-03 independence_day*', '2026-07-04 independence_day', '2026-09-07 labor_day',
      '2026-10-12 columbus_day', '2026-11-11 veterans_day', '2026-11-26 thanksgiving', '2026-12-25 christmas',
    ]);
    expect(us.on(CivilDate(2027, 12, 31)).single.substitute, isTrue, reason: '1/1/2028 là thứ Bảy');
    expect(us.on(CivilDate(2027, 12, 24)).single.id, 'christmas');
    expect(us.inYear(2020).any((h) => h.id == 'juneteenth'), isFalse, reason: 'từ 2021');
    expect(us.on(CivilDate(2026, 5, 10)).single.name('en'), "Mother's Day");
  });

  test('GB: Phục sinh, ngày bù không trùng ngày lễ khác, ngày dời và ngày lễ 1 lần', () {
    final gb = pack('GB');
    expect(days(gb, 2026), [
      '2026-01-01 new_year', '2026-04-03 good_friday', '2026-04-06 easter_monday', '2026-05-04 early_may', '2026-05-25 spring_bank',
      '2026-08-31 summer_bank', '2026-12-25 christmas', '2026-12-26 boxing_day', '2026-12-28 boxing_day*',
    ]);
    expect(days(gb, 2027).where((d) => d.startsWith('2027-12')), ['2027-12-25 christmas', '2027-12-26 boxing_day', '2027-12-27 christmas*', '2027-12-28 boxing_day*']);
    expect(days(gb, 2022), containsAll(['2022-01-03 new_year*', '2022-06-02 spring_bank', '2022-06-03 platinum_jubilee', '2022-09-19 state_funeral', '2022-12-27 christmas*']));
    expect(days(gb, 2022).where((d) => d.contains('2022-05-30')), isEmpty, reason: 'spring bank 2022 dời sang 2/6');
  });

  test('between gồm 2 đầu, qua năm', () {
    final vn = pack('VN');
    expect(vn.between(CivilDate(2025, 12, 31), CivilDate(2026, 1, 1)).map((h) => h.id), ['new_year']);
  });

  test('luật không hỗ trợ thì báo lỗi rõ', () {
    expect(() => HolidayCalendar.parse('{"region":"XX","version":1,"holidays":[{"id":"a","names":{"en":"A"},"rule":{"type":"hijri"}}]}'),
        throwsFormatException);
  });

  test('mọi gói trong data/holidays đọc được, đúng tên vùng, có tên en, có trong assets của pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final f in Directory('data/holidays').listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      final region = f.uri.pathSegments.last.split('.').first;
      final c = HolidayCalendar.parse(f.readAsStringSync());
      expect(c.region, region);
      expect(pubspec, contains('data/holidays/$region.json'));
      for (final y in [2025, 2030, 2050]) {
        for (final h in c.inYear(y)) {
          expect(h.names['en'], isNotNull, reason: '${h.id} thiếu tên en');
        }
      }
    }
  });

  test('cuối tuần theo CLDR weekData', () {
    expect(weekendDays('VN'), {DateTime.saturday, DateTime.sunday});
    expect(weekendDays('SA'), {DateTime.friday, DateTime.saturday});
    expect(weekendDays('IN'), {DateTime.sunday});
    expect(weekendDays(null), {DateTime.saturday, DateTime.sunday});
  });

  group('lặp ngày làm việc', () {
    tearDown(HolidayCalendars.clear);
    final row = {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR', 'workdays_region': 'VN'};
    final start = CivilDateTime(CivilDate(2026, 4, 1), CivilTime(8));

    test('bỏ ngày nghỉ lễ của vùng (30/4, 1/5), giữ ngày kỷ niệm', () {
      HolidayCalendars.register(pack('VN'));
      final r = Recurrence.fromRow(row);
      expect([for (final o in r.between(start, CivilDate(2026, 4, 27), CivilDate(2026, 5, 4))) o.date.toIso()],
          ['2026-04-27', '2026-04-28', '2026-04-29', '2026-05-04']);
      expect(r.nextAfter(start, CivilDateTime(CivilDate(2026, 4, 29), CivilTime(9)))!.date.toIso(), '2026-05-04');
      expect(r.between(start, CivilDate(2026, 10, 20), CivilDate(2026, 10, 20)), hasLength(1), reason: '20/10 (thứ Ba) là ngày kỷ niệm, không nghỉ');
      expect(r.between(start, CivilDate(2026, 3, 1), CivilDate(2026, 3, 31)), isEmpty, reason: 'khoảng trước ngày bắt đầu chuỗi');
    });

    test('vùng chưa nạp gói: chỉ bỏ cuối tuần như quy tắc gốc', () {
      expect(Recurrence.fromRow(row).between(start, CivilDate(2026, 4, 27), CivilDate(2026, 5, 4)), hasLength(6));
    });
  });
}
