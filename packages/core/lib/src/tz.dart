import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'civil.dart';

/// Kết quả đổi giờ tường sang UTC.
class ResolvedInstant {
  const ResolvedInstant(this.utc, {this.dstAdjusted = false});
  final DateTime utc;
  /// Giờ tường không tồn tại (ngày chuyển sang giờ mùa hè) hoặc lặp 2 lần (ngày lùi giờ): đã áp quy tắc §5.
  final bool dstAdjusted;
}

/// Đổi giờ tường ↔ UTC theo tzdata IANA (package `timezone`, cập nhật mỗi bản phát hành), reminder-engine.md §5:
/// - giờ **không tồn tại** (02:30 ngày chuyển giờ mùa hè) → thời điểm hợp lệ kế tiếp (03:00);
/// - giờ **lặp 2 lần** (01:30 ngày lùi giờ) → lần đầu.
class TimeZones {
  TimeZones._();
  static bool _ready = false;

  static void ensureInitialized() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  static bool isValid(String name) {
    ensureInitialized();
    try {
      tz.getLocation(name);
      return true;
    } on Object {
      return false;
    }
  }

  static tz.Location _loc(String name) {
    ensureInitialized();
    return tz.getLocation(name);
  }

  static int _offsetMs(tz.Location loc, int utcMs) => loc.timeZone(utcMs).offset.inMilliseconds;

  /// Giờ tường [wall] (giờ null = 00:00) ở múi [zone] → UTC.
  static ResolvedInstant toUtc(CivilDateTime wall, String zone) {
    final loc = _loc(zone);
    final w = DateTime.utc(wall.date.year, wall.date.month, wall.date.day, wall.time?.hour ?? 0, wall.time?.minute ?? 0)
        .millisecondsSinceEpoch;
    // Độ lệch có thể có quanh thời điểm này: trước và sau tối đa 1 ngày.
    final offsets = {_offsetMs(loc, w - 86400000), _offsetMs(loc, w), _offsetMs(loc, w + 86400000)};
    final valid = [
      for (final o in offsets)
        if (_offsetMs(loc, w - o) == o) w - o,
    ]..sort();
    if (valid.length == 1) return ResolvedInstant(DateTime.fromMillisecondsSinceEpoch(valid.first, isUtc: true));
    if (valid.length > 1) {
      return ResolvedInstant(DateTime.fromMillisecondsSinceEpoch(valid.first, isUtc: true), dstAdjusted: true);
    }
    // Rơi vào khoảng trống: lấy thời điểm chuyển giờ (giờ tường hợp lệ đầu tiên sau khoảng trống).
    final before = _offsetMs(loc, w - 86400000);
    var lo = w - before - 86400000, hi = w - before; // offset(lo) = before, offset(hi) ≠ before
    while (hi - lo > 60000) {
      final mid = lo + (hi - lo) ~/ 2;
      if (_offsetMs(loc, mid) == before) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    // Chuyển giờ xảy ra ở phút tròn.
    final transition = (hi ~/ 60000) * 60000;
    return ResolvedInstant(DateTime.fromMillisecondsSinceEpoch(transition, isUtc: true), dstAdjusted: true);
  }

  /// UTC → giờ tường ở [zone].
  static CivilDateTime toWall(DateTime utc, String zone) {
    final loc = _loc(zone);
    final ms = utc.millisecondsSinceEpoch;
    final w = DateTime.fromMillisecondsSinceEpoch(ms + _offsetMs(loc, ms), isUtc: true);
    return CivilDateTime(CivilDate(w.year, w.month, w.day), CivilTime(w.hour, w.minute));
  }

  /// [start, end) UTC của ngày [date] ở [zone] (ngày DST dài 23/25 giờ).
  static (DateTime, DateTime) dayBounds(CivilDate date, String zone) =>
      (toUtc(CivilDateTime(date, CivilTime(0)), zone).utc, toUtc(CivilDateTime(date.addDays(1), CivilTime(0)), zone).utc);
}
