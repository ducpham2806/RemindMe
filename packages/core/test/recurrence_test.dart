import 'package:remindme_core/remindme_core.dart';
import 'package:test/test.dart';

CivilDate d(int y, int m, int day) => CivilDate(y, m, day);

void main() {
  group('âm lịch', () {
    const vi = LunarCalendar(LunarSystem.vi), zh = LunarCalendar(LunarSystem.zh);

    test('Tết Nguyên đán (mùng 1 tháng giêng) VN', () {
      final tet = {2023: d(2023, 1, 22), 2024: d(2024, 2, 10), 2025: d(2025, 1, 29), 2026: d(2026, 2, 17), 2027: d(2027, 2, 6)};
      tet.forEach((y, solar) {
        expect(vi.toSolar(LunarDate(y, 1, 1)), solar, reason: 'Tết $y');
        expect(vi.fromSolar(solar), LunarDate(y, 1, 1));
      });
    });

    test('múi giờ khác nên Tết VN và TQ lệch ở 1985, 2007', () {
      expect(vi.toSolar(const LunarDate(2007, 1, 1)), d(2007, 2, 17));
      expect(zh.toSolar(const LunarDate(2007, 1, 1)), d(2007, 2, 18));
      expect(vi.toSolar(const LunarDate(1985, 1, 1)), d(1985, 1, 21));
      expect(zh.toSolar(const LunarDate(1985, 1, 1)), d(1985, 2, 20));
    });

    test('ngày lễ: Trung thu, Giỗ Tổ 10/3, rằm tháng giêng', () {
      expect(vi.toSolar(const LunarDate(2024, 8, 15)), d(2024, 9, 17));
      expect(vi.toSolar(const LunarDate(2025, 8, 15)), d(2025, 10, 6));
      expect(vi.toSolar(const LunarDate(2026, 8, 15)), d(2026, 9, 25));
      expect(vi.toSolar(const LunarDate(2026, 3, 10)), d(2026, 4, 26));
      expect(vi.toSolar(const LunarDate(2026, 1, 15)), d(2026, 3, 3));
    });

    test('tháng nhuận: 2023 nhuận tháng 2, 2025 nhuận tháng 6', () {
      expect(vi.monthOf(2023, 2, leap: true)!.start, d(2023, 3, 22));
      expect(vi.monthOf(2023, 2)!.start, d(2023, 2, 20));
      expect(vi.monthOf(2025, 6, leap: true)!.start, d(2025, 7, 25));
      expect(vi.monthOf(2026, 6, leap: true), isNull, reason: '2026 không nhuận');
      expect(vi.fromSolar(d(2025, 8, 1)), const LunarDate(2025, 6, 8, leap: true));
    });

    test('đổi qua lại 2 chiều trong 3 năm liền không lệch', () {
      for (var x = d(2025, 1, 1); x.isBefore(d(2028, 1, 1)); x = x.addDays(1)) {
        expect(vi.toSolar(vi.fromSolar(x)), x, reason: '$x');
      }
    });
  });

  group('Recurrence', () {
    test('rrule: hằng ngày lúc 8h, có exdate', () {
      final r = RRuleRecurrence('FREQ=DAILY');
      final start = CivilDateTime(d(2026, 12, 1), CivilTime(8));
      final got = r.between(start, d(2026, 12, 1), d(2026, 12, 4), exdates: {CivilDateTime(d(2026, 12, 2), CivilTime(8))});
      expect(got.map((o) => '$o'), ['2026-12-01 08:00', '2026-12-03 08:00', '2026-12-04 08:00']);
    });

    test('rrule: thứ 2,4,6; mỗi 2 tuần thứ 3; ngày 31 hằng tháng bỏ tháng thiếu (RFC 5545)', () {
      final start = CivilDateTime(d(2026, 12, 1), CivilTime(6));
      expect(RRuleRecurrence('FREQ=WEEKLY;BYDAY=MO,WE,FR').between(start, d(2026, 12, 1), d(2026, 12, 7)).map((o) => o.date.day), [2, 4, 7]);
      expect(RRuleRecurrence('FREQ=WEEKLY;INTERVAL=2;BYDAY=TU').between(start, d(2026, 12, 1), d(2026, 12, 31)).map((o) => o.date.day), [1, 15, 29]);
      final m31 = RRuleRecurrence('FREQ=MONTHLY;BYMONTHDAY=31').between(CivilDateTime(d(2027, 1, 31)), d(2027, 1, 1), d(2027, 5, 31));
      expect(m31.map((o) => o.date.month), [1, 3, 5]);
      expect(m31.first.time, isNull, reason: 'chuỗi cả ngày không có giờ');
    });

    test('rrule: thứ 6 cuối cùng của tháng, ngày cuối tháng', () {
      final start = CivilDateTime(d(2026, 1, 1));
      expect(RRuleRecurrence('FREQ=MONTHLY;BYDAY=-1FR').between(start, d(2026, 1, 1), d(2026, 3, 31)).map((o) => '${o.date}'),
          ['2026-01-30', '2026-02-27', '2026-03-27']);
      expect(RRuleRecurrence('FREQ=MONTHLY;BYMONTHDAY=-1').between(start, d(2028, 1, 1), d(2028, 3, 31)).map((o) => o.date.day), [31, 29, 31]);
    });

    test('giờ tường giữ nguyên qua ngày đổi giờ DST (không giữ khoảng 24h)', () {
      // New York đổi giờ 8/3/2026: chuỗi 08:00 vẫn là 08:00 mỗi ngày; đổi sang UTC theo tz ở tầng nhắc.
      final got = RRuleRecurrence('FREQ=DAILY').between(CivilDateTime(d(2026, 3, 7), CivilTime(8)), d(2026, 3, 7), d(2026, 3, 9));
      expect(got.map((o) => o.time), everyElement(CivilTime(8)));
    });

    test('âm lịch hằng tháng: rằm, bỏ tháng nhuận (mặc định) hoặc kêu cả 2', () {
      final ram = LunarRecurrence(LunarSystem.vi, day: 15);
      final start = CivilDateTime(d(2025, 6, 1), CivilTime(6));
      final skip = ram.between(start, d(2025, 6, 1), d(2025, 9, 30));
      expect(skip.map((o) => '${o.date}'), ['2025-06-10', '2025-07-09', '2025-09-06']);
      final both = LunarRecurrence(LunarSystem.vi, day: 15, leap: LeapRule.both).between(start, d(2025, 6, 1), d(2025, 9, 30));
      expect(both.map((o) => '${o.date}'), ['2025-06-10', '2025-07-09', '2025-08-08', '2025-09-06']);
      expect(skip.first.time, CivilTime(6));
    });

    test('âm lịch hằng năm: giỗ 10/3; ngày 30 của tháng thiếu lấy ngày 29', () {
      final gio = LunarRecurrence(LunarSystem.vi, day: 10, month: 3);
      expect(gio.nextAfter(CivilDateTime(d(2026, 1, 1)), CivilDateTime(d(2026, 1, 1)))!.date, d(2026, 4, 26));
      final cal = const LunarCalendar(LunarSystem.vi);
      final short = cal.monthsBetween(d(2026, 1, 1), d(2026, 12, 31)).firstWhere((m) => m.length == 29);
      final r30 = LunarRecurrence(LunarSystem.vi, day: 30, month: short.leap ? null : short.month);
      final hit = r30.between(CivilDateTime(short.start), short.start, short.start.addDays(28));
      expect(hit.single.date, short.start.addDays(28));
    });

    test('fromRow đọc đúng hàng recurrences; after_completion tính từ ngày xong', () {
      expect(Recurrence.fromRow({'kind': 'rrule', 'rrule': 'FREQ=DAILY'}), isA<RRuleRecurrence>());
      final l = Recurrence.fromRow({'kind': 'calendar', 'calendar': {'system': 'lunar_vi', 'day': 1}}) as LunarRecurrence;
      expect((l.day, l.month, l.leap), (1, null, LeapRule.skip));
      final a = Recurrence.fromRow({'kind': 'after_completion', 'interval_days': 30}) as AfterCompletion;
      expect(a.nextFromCompletion(d(2026, 12, 20), null).date, d(2027, 1, 19));
      expect(() => Recurrence.fromRow({'kind': 'calendar', 'calendar': {'system': 'hijri', 'day': 1}}), throwsArgumentError);
    });

    test('nextAfter', () {
      final r = RRuleRecurrence('FREQ=WEEKLY;BYDAY=MO');
      final start = CivilDateTime(d(2026, 12, 1), CivilTime(9));
      expect(r.nextAfter(start, CivilDateTime(d(2026, 12, 7), CivilTime(9)))!.date, d(2026, 12, 14));
      expect(RRuleRecurrence('FREQ=DAILY;COUNT=2').nextAfter(start, CivilDateTime(d(2026, 12, 2), CivilTime(9))), isNull);
    });
  });
}
