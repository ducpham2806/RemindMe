/// Ngày lịch không gắn múi giờ (ngày "trên tờ lịch"). Đổi sang thời điểm UTC cần `tz` IANA, làm ở tầng app.
/// Tính toán qua DateTime.utc để không bị DST của máy chạy code làm lệch ngày.
class CivilDate implements Comparable<CivilDate> {
  factory CivilDate(int year, int month, int day) {
    final d = DateTime.utc(year, month, day);
    if (d.year != year || d.month != month || d.day != day) {
      throw ArgumentError('ngày không hợp lệ: $year-$month-$day');
    }
    return CivilDate._(year, month, day);
  }
  const CivilDate._(this.year, this.month, this.day);

  /// Lấy phần năm/tháng/ngày của [d] như nó đang hiển thị (local hay UTC tùy [d]).
  factory CivilDate.of(DateTime d) => CivilDate._(d.year, d.month, d.day);

  /// 'YYYY-MM-DD'.
  factory CivilDate.parse(String iso) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (m == null) throw FormatException('không phải YYYY-MM-DD', iso);
    return CivilDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  /// Ngày hợp lệ hay không (ví dụ 31/4 → false), không ném lỗi.
  static bool isValid(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1) return false;
    final d = DateTime.utc(year, month, day);
    return d.month == month && d.day == day;
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// ISO: 1 = thứ Hai … 7 = Chủ nhật.
  int get weekday => _utc.weekday;

  CivilDate addDays(int n) => CivilDate.of(_utc.add(Duration(days: n)));

  /// Cộng tháng, kẹp ngày về cuối tháng nếu thiếu (31/1 + 1 tháng = 28 hoặc 29/2).
  CivilDate addMonths(int n) {
    final total = year * 12 + (month - 1) + n;
    final y = total ~/ 12, m = total % 12 + 1;
    final last = DateTime.utc(y, m + 1, 0).day;
    return CivilDate._(y, m, day > last ? last : day);
  }

  /// Số ngày từ [other] tới ngày này (dương nếu ngày này sau [other]).
  int daysSince(CivilDate other) => _utc.difference(other._utc).inDays;

  /// Thứ [weekday] đầu tiên từ ngày này trở đi (gồm cả hôm nay).
  CivilDate nextOrSame(int weekday) => addDays((weekday - this.weekday) % 7);

  bool isBefore(CivilDate o) => compareTo(o) < 0;
  bool isAfter(CivilDate o) => compareTo(o) > 0;

  @override
  int compareTo(CivilDate o) => year != o.year ? year - o.year : (month != o.month ? month - o.month : day - o.day);

  @override
  bool operator ==(Object other) => other is CivilDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  String toIso() => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  String toString() => toIso();
}

/// Giờ trên đồng hồ treo tường (không múi giờ).
class CivilTime implements Comparable<CivilTime> {
  CivilTime(this.hour, [this.minute = 0]) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) throw ArgumentError('giờ không hợp lệ: $hour:$minute');
  }

  factory CivilTime.of(DateTime d) => CivilTime(d.hour, d.minute);

  /// 'HH:MM'.
  factory CivilTime.parse(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (m == null) throw FormatException('không phải HH:MM', s);
    return CivilTime(int.parse(m[1]!), int.parse(m[2]!));
  }

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  @override
  int compareTo(CivilTime o) => minutesOfDay - o.minutesOfDay;

  @override
  bool operator ==(Object other) => other is CivilTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
