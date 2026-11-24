import 'package:remindme_core/remindme_core.dart';
import 'package:test/test.dart';

CivilDateTime w(int y, int m, int d, int h, [int min = 0]) => CivilDateTime(CivilDate(y, m, d), CivilTime(h, min));

void main() {
  // Vùng bắt buộc test (reminder-engine.md §5).
  test('vùng không DST và lệch lẻ phút', () {
    expect(TimeZones.toUtc(w(2026, 12, 1, 8), 'Asia/Ho_Chi_Minh').utc, DateTime.utc(2026, 12, 1, 1));
    expect(TimeZones.toUtc(w(2026, 12, 1, 8), 'Asia/Kolkata').utc, DateTime.utc(2026, 12, 1, 2, 30));
    expect(TimeZones.toUtc(w(2026, 12, 1, 8), 'Asia/Kathmandu').utc, DateTime.utc(2026, 12, 1, 2, 15));
    // Chatham mùa hè (+13:45) vào tháng 12.
    expect(TimeZones.toUtc(w(2026, 12, 1, 8), 'Pacific/Chatham').utc, DateTime.utc(2026, 11, 30, 18, 15));
  });

  test('New York: 02:30 ngày 8/3/2026 không tồn tại → 03:00; 01:30 ngày 1/11/2026 lặp → lần đầu (EDT)', () {
    final gap = TimeZones.toUtc(w(2026, 3, 8, 2, 30), 'America/New_York');
    expect(gap.utc, DateTime.utc(2026, 3, 8, 7));
    expect(gap.dstAdjusted, isTrue);
    expect(TimeZones.toWall(gap.utc, 'America/New_York'), w(2026, 3, 8, 3));
    final dup = TimeZones.toUtc(w(2026, 11, 1, 1, 30), 'America/New_York');
    expect(dup.utc, DateTime.utc(2026, 11, 1, 5, 30));
    expect(dup.dstAdjusted, isTrue);
    expect(TimeZones.toUtc(w(2026, 11, 2, 1, 30), 'America/New_York').dstAdjusted, isFalse);
  });

  test('London và Sydney (DST ngược mùa)', () {
    expect(TimeZones.toUtc(w(2026, 3, 29, 1, 30), 'Europe/London').utc, DateTime.utc(2026, 3, 29, 1));
    expect(TimeZones.toUtc(w(2026, 7, 1, 9), 'Europe/London').utc, DateTime.utc(2026, 7, 1, 8));
    // Sydney: tháng 1 là giờ mùa hè (+11), tháng 7 là +10; đổi giờ 4/10/2026 02:00 → 03:00.
    expect(TimeZones.toUtc(w(2026, 1, 15, 9), 'Australia/Sydney').utc, DateTime.utc(2026, 1, 14, 22));
    expect(TimeZones.toUtc(w(2026, 7, 15, 9), 'Australia/Sydney').utc, DateTime.utc(2026, 7, 14, 23));
    expect(TimeZones.toUtc(w(2026, 10, 4, 2, 15), 'Australia/Sydney').utc, DateTime.utc(2026, 10, 3, 16));
  });

  test('ngày đổi giờ dài 23 / 25 giờ; tz không hợp lệ', () {
    final (a, b) = TimeZones.dayBounds(CivilDate(2026, 3, 8), 'America/New_York');
    expect(b.difference(a).inHours, 23);
    final (c, d) = TimeZones.dayBounds(CivilDate(2026, 11, 1), 'America/New_York');
    expect(d.difference(c).inHours, 25);
    expect(TimeZones.isValid('Mars/Olympus'), isFalse);
    expect(TimeZones.isValid('Etc/GMT-7'), isTrue);
  });
}
