import 'dart:math' as math;

import 'civil.dart';

/// Âm lịch (âm dương lịch) VN/TQ/HQ theo thuật toán của Hồ Ngọc Đức (tính điểm sóc và trung khí bằng công thức thiên văn).
/// Khác nhau giữa các nước chỉ ở múi giờ tính ngày: VN UTC+7, TQ UTC+8, HQ UTC+9 (reminder-engine.md §4, ADR-007).
/// Vì múi giờ khác, Tết VN và TQ lệch nhau ở vài năm (1985, 2007).
enum LunarSystem {
  vi('lunar_vi', 7),
  zh('lunar_zh', 8),
  ko('lunar_ko', 9);

  const LunarSystem(this.wire, this.utcOffsetHours);
  final String wire;
  final int utcOffsetHours;

  static LunarSystem fromWire(String s) =>
      values.firstWhere((v) => v.wire == s, orElse: () => throw ArgumentError.value(s, 'system', 'hệ lịch không hỗ trợ'));
}

class LunarDate {
  const LunarDate(this.year, this.month, this.day, {this.leap = false});
  final int year;
  final int month;
  final int day;
  /// Tháng nhuận.
  final bool leap;

  @override
  bool operator ==(Object other) =>
      other is LunarDate && other.year == year && other.month == month && other.day == day && other.leap == leap;
  @override
  int get hashCode => Object.hash(year, month, day, leap);
  @override
  String toString() => '$day/$month${leap ? 'N' : ''}/$year';
}

/// Một tháng âm lịch: ngày dương bắt đầu (mùng 1) và số ngày (29 hoặc 30).
class LunarMonth {
  const LunarMonth(this.year, this.month, this.leap, this.start, this.length);
  final int year;
  final int month;
  final bool leap;
  final CivilDate start;
  final int length;
}

class LunarCalendar {
  const LunarCalendar(this.system);
  final LunarSystem system;

  int get _tz => system.utcOffsetHours;

  LunarDate fromSolar(CivilDate d) {
    final dayNumber = _jdFromDate(d.day, d.month, d.year);
    final k = ((dayNumber - 2415021.076998695) / 29.530588853).floor();
    var monthStart = _newMoonDay(k + 1);
    if (monthStart > dayNumber) monthStart = _newMoonDay(k);
    var a11 = _lunarMonth11(d.year);
    var b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = d.year;
      a11 = _lunarMonth11(d.year - 1);
    } else {
      lunarYear = d.year + 1;
      b11 = _lunarMonth11(d.year + 1);
    }
    final lunarDay = dayNumber - monthStart + 1;
    final diff = ((monthStart - a11) / 29).floor();
    var leap = false;
    var lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      final leapMonthDiff = _leapMonthOffset(a11);
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        if (diff == leapMonthDiff) leap = true;
      }
    }
    if (lunarMonth > 12) lunarMonth -= 12;
    if (lunarMonth >= 11 && diff < 4) lunarYear -= 1;
    return LunarDate(lunarYear, lunarMonth, lunarDay, leap: leap);
  }

  /// Ngày dương của [l]; null nếu không có (tháng nhuận không tồn tại năm đó, hoặc ngày 30 của tháng thiếu).
  CivilDate? toSolar(LunarDate l) {
    final m = monthOf(l.year, l.month, leap: l.leap);
    if (m == null || l.day < 1 || l.day > m.length) return null;
    return m.start.addDays(l.day - 1);
  }

  /// Tháng âm [month] (nhuận nếu [leap]) của năm âm [year]; null nếu năm đó không có tháng nhuận này.
  LunarMonth? monthOf(int year, int month, {bool leap = false}) {
    int a11, b11;
    if (month < 11) {
      a11 = _lunarMonth11(year - 1);
      b11 = _lunarMonth11(year);
    } else {
      a11 = _lunarMonth11(year);
      b11 = _lunarMonth11(year + 1);
    }
    final k = (0.5 + (a11 - 2415021.076998695) / 29.530588853).floor();
    var off = month - 11;
    if (off < 0) off += 12;
    if (b11 - a11 > 365) {
      final leapOff = _leapMonthOffset(a11);
      var leapMonth = leapOff - 2;
      if (leapMonth < 0) leapMonth += 12;
      if (leap && month != leapMonth) return null;
      if (leap || off >= leapOff) off += 1;
    } else if (leap) {
      return null;
    }
    final start = _newMoonDay(k + off);
    final next = _newMoonDay(k + off + 1);
    return LunarMonth(year, month, leap, _dateFromJd(start), next - start);
  }

  /// Mọi tháng âm có mùng 1 trong [from − 30 ngày, to], theo thứ tự (gồm tháng nhuận).
  Iterable<LunarMonth> monthsBetween(CivilDate from, CivilDate to) sync* {
    final startJd = _jdFromDate(from.day, from.month, from.year) - 30;
    final endJd = _jdFromDate(to.day, to.month, to.year);
    var k = ((startJd - 2415021.076998695) / 29.530588853).floor();
    while (true) {
      final s = _newMoonDay(k);
      if (s > endJd) return;
      final next = _newMoonDay(k + 1);
      if (next > startJd) {
        final first = _dateFromJd(s);
        final l = fromSolar(first);
        yield LunarMonth(l.year, l.month, l.leap, first, next - s);
      }
      k++;
    }
  }

  // ------------------------------------------------------------------ thiên văn

  static int _jdFromDate(int dd, int mm, int yy) {
    final a = (14 - mm) ~/ 12;
    final y = yy + 4800 - a;
    final m = mm + 12 * a - 3;
    var jd = dd + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
    if (jd < 2299161) jd = dd + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - 32083;
    return jd;
  }

  static CivilDate _dateFromJd(int jd) {
    int b, c;
    if (jd > 2299160) {
      final a = jd + 32044;
      b = (4 * a + 3) ~/ 146097;
      c = a - (b * 146097) ~/ 4;
    } else {
      b = 0;
      c = jd + 32082;
    }
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = b * 100 + d - 4800 + m ~/ 10;
    return CivilDate(year, month, day);
  }

  /// Thời điểm sóc thứ k (JD, giờ UT) tính từ sóc 1/1/1900.
  static double _newMoon(int k) {
    final t = k / 1236.85, t2 = t * t, t3 = t2 * t;
    const dr = math.pi / 180;
    var jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;
    jd1 += 0.00033 * math.sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);
    final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final mpr = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;
    var c1 = (0.1734 - 0.000393 * t) * math.sin(m * dr) + 0.0021 * math.sin(2 * dr * m);
    c1 = c1 - 0.4068 * math.sin(mpr * dr) + 0.0161 * math.sin(dr * 2 * mpr);
    c1 = c1 - 0.0004 * math.sin(dr * 3 * mpr);
    c1 = c1 + 0.0104 * math.sin(dr * 2 * f) - 0.0051 * math.sin(dr * (m + mpr));
    c1 = c1 - 0.0074 * math.sin(dr * (m - mpr)) + 0.0004 * math.sin(dr * (2 * f + m));
    c1 = c1 - 0.0004 * math.sin(dr * (2 * f - m)) - 0.0006 * math.sin(dr * (2 * f + mpr));
    c1 = c1 + 0.0010 * math.sin(dr * (2 * f - mpr)) + 0.0005 * math.sin(dr * (2 * mpr + m));
    final deltat = t < -11
        ? 0.001 + 0.000839 * t + 0.0002261 * t2 - 0.00000845 * t3 - 0.000000081 * t * t3
        : -0.000278 + 0.000265 * t + 0.000262 * t2;
    return jd1 + c1 - deltat;
  }

  /// Kinh độ mặt trời (radian) tại JD.
  static double _sunLongitude(double jdn) {
    final t = (jdn - 2451545.0) / 36525, t2 = t * t;
    const dr = math.pi / 180;
    final m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
    final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(dr * m);
    dl = dl + (0.019993 - 0.000101 * t) * math.sin(dr * 2 * m) + 0.000290 * math.sin(dr * 3 * m);
    var l = (l0 + dl) * dr;
    l = l - math.pi * 2 * (l / (math.pi * 2)).floor();
    return l;
  }

  int _newMoonDay(int k) => (_newMoon(k) + 0.5 + _tz / 24).floor();

  /// Cung hoàng đạo (0-11) của mặt trời đầu ngày [dayNumber] theo giờ địa phương.
  int _sunLongitudeSector(int dayNumber) => (_sunLongitude(dayNumber - 0.5 - _tz / 24) / math.pi * 6).floor();

  /// Mùng 1 tháng 11 âm (tháng chứa Đông chí) của năm dương [yy].
  int _lunarMonth11(int yy) {
    final off = _jdFromDate(31, 12, yy) - 2415021;
    final k = (off / 29.530588853).floor();
    var nm = _newMoonDay(k);
    if (_sunLongitudeSector(nm) >= 9) nm = _newMoonDay(k - 1);
    return nm;
  }

  /// Vị trí tháng nhuận tính từ tháng 11 (tháng đầu tiên không có trung khí).
  int _leapMonthOffset(int a11) {
    final k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).floor();
    var i = 1;
    var arc = _sunLongitudeSector(_newMoonDay(k + i));
    int last;
    do {
      last = arc;
      i++;
      arc = _sunLongitudeSector(_newMoonDay(k + i));
    } while (arc != last && i < 14);
    return i - 1;
  }
}
