import 'package:remindme_core/remindme_core.dart';
import 'package:test/test.dart';

void main() {
  test('CivilDate: kiểm tra hợp lệ, thứ, cộng ngày qua năm nhuận', () {
    expect(() => CivilDate(2026, 2, 29), throwsArgumentError);
    expect(CivilDate.isValid(2028, 2, 29), isTrue);
    expect(CivilDate.isValid(2026, 4, 31), isFalse);
    expect(CivilDate(2026, 12, 1).weekday, DateTime.tuesday);
    expect(CivilDate(2028, 2, 28).addDays(1), CivilDate(2028, 2, 29));
    expect(CivilDate(2026, 12, 31).addDays(1), CivilDate(2027, 1, 1));
    expect(CivilDate(2027, 1, 1).daysSince(CivilDate(2026, 12, 1)), 31);
  });

  test('addMonths kẹp về cuối tháng', () {
    expect(CivilDate(2026, 1, 31).addMonths(1), CivilDate(2026, 2, 28));
    expect(CivilDate(2026, 11, 30).addMonths(3), CivilDate(2027, 2, 28));
    expect(CivilDate(2026, 3, 15).addMonths(-3), CivilDate(2025, 12, 15));
  });

  test('nextOrSame, parse, so sánh, CivilTime', () {
    final tue = CivilDate(2026, 12, 1);
    expect(tue.nextOrSame(DateTime.tuesday), tue);
    expect(tue.nextOrSame(DateTime.monday), CivilDate(2026, 12, 7));
    expect(CivilDate.parse('2026-03-08').toIso(), '2026-03-08');
    expect(CivilDate(2026, 1, 2).isBefore(CivilDate(2026, 1, 10)), isTrue);
    expect(CivilTime.parse('7:05').toString(), '07:05');
    expect(() => CivilTime(24), throwsArgumentError);
    expect(CivilTime(14, 30).compareTo(CivilTime(9)), greaterThan(0));
  });
}
