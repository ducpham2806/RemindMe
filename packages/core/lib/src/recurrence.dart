import 'package:rrule/rrule.dart' as rr;

import 'civil.dart';
import 'lunar.dart';

/// Lặp lại (reminder-engine.md §4), cùng dạng hàng bảng `recurrences`: rrule | calendar | after_completion.
/// Tính trên giờ tường (CivilDateTime); đổi sang UTC theo `tz`/`time_mode` ở tầng nhắc (§5), nên chuỗi giữ giờ địa phương qua DST.
sealed class Recurrence {
  const Recurrence();

  factory Recurrence.fromRow(Map<String, Object?> row) {
    switch (row['kind']) {
      case 'rrule':
        return RRuleRecurrence(row['rrule']! as String);
      case 'calendar':
        final c = (row['calendar']! as Map).cast<String, Object?>();
        return LunarRecurrence(LunarSystem.fromWire(c['system']! as String),
            day: c['day']! as int, month: c['month'] as int?, leap: LeapRule.fromWire(c['leap'] as String?));
      case 'after_completion':
        return AfterCompletion(row['interval_days']! as int);
      default:
        throw ArgumentError.value(row['kind'], 'kind');
    }
  }

  /// Các lần từ [from] tới [to] (gồm 2 đầu, theo ngày), không trước [start], bỏ [exdates]. Tối đa [limit] lần.
  List<CivilDateTime> between(CivilDateTime start, CivilDate from, CivilDate to,
      {Set<CivilDateTime> exdates = const {}, int limit = 1000});

  /// Lần đầu tiên sau [after] (không tính đúng [after]); null nếu chuỗi đã hết trong 5 năm tới.
  CivilDateTime? nextAfter(CivilDateTime start, CivilDateTime after, {Set<CivilDateTime> exdates = const {}}) {
    var from = after.date;
    for (var i = 0; i < 5; i++) {
      final to = from.addDays(366);
      for (final o in between(start, from, to, exdates: exdates, limit: 400)) {
        if (o.compareTo(after) > 0) return o;
      }
      from = to.addDays(1);
    }
    return null;
  }
}

/// RRULE (RFC 5545), dạng `FREQ=...;...` không có tiền tố `RRULE:` (khớp server `app.rrule_fires_on`).
class RRuleRecurrence extends Recurrence {
  RRuleRecurrence(this.rrule) : _rule = rr.RecurrenceRule.fromString('RRULE:${rrule.replaceFirst(RegExp('^RRULE:', caseSensitive: false), '')}');
  final String rrule;
  final rr.RecurrenceRule _rule;

  @override
  List<CivilDateTime> between(CivilDateTime start, CivilDate from, CivilDate to,
      {Set<CivilDateTime> exdates = const {}, int limit = 1000}) {
    // rrule tính trên DateTime UTC như giờ tường: không có DST xen vào.
    final s = _utc(start);
    final fromUtc = DateTime.utc(from.year, from.month, from.day);
    final out = <CivilDateTime>[];
    for (final d in _rule.getInstances(
      start: s,
      after: fromUtc.isBefore(s) ? s : fromUtc,
      includeAfter: true,
      before: DateTime.utc(to.year, to.month, to.day).add(const Duration(days: 1)),
    )) {
      final o = CivilDateTime(CivilDate(d.year, d.month, d.day), start.time == null && d.hour == 0 && d.minute == 0 ? null : CivilTime(d.hour, d.minute));
      if (exdates.contains(o)) continue;
      out.add(o);
      if (out.length >= limit) break;
    }
    return out;
  }

  static DateTime _utc(CivilDateTime c) => DateTime.utc(c.date.year, c.date.month, c.date.day, c.time?.hour ?? 0, c.time?.minute ?? 0);
}

/// Tháng nhuận: `skip` = không kêu trong tháng nhuận (mặc định); `both` = kêu cả tháng thường và tháng nhuận.
enum LeapRule {
  skip,
  both;

  static LeapRule fromWire(String? s) => s == 'both' ? both : skip;
}

/// Âm lịch: hằng tháng ([month] null, ví dụ rằm = ngày 15) hoặc hằng năm (giỗ 10/3).
/// Tháng thiếu (29 ngày) không có ngày 30: lấy ngày 29.
class LunarRecurrence extends Recurrence {
  LunarRecurrence(this.system, {required this.day, this.month, this.leap = LeapRule.skip})
      : assert(day >= 1 && day <= 30),
        assert(month == null || (month >= 1 && month <= 12));
  final LunarSystem system;
  final int day;
  final int? month;
  final LeapRule leap;

  @override
  List<CivilDateTime> between(CivilDateTime start, CivilDate from, CivilDate to,
      {Set<CivilDateTime> exdates = const {}, int limit = 1000}) {
    final cal = LunarCalendar(system);
    final out = <CivilDateTime>[];
    for (final m in cal.monthsBetween(from, to)) {
      if (m.leap && leap == LeapRule.skip) continue;
      if (month != null && m.month != month) continue;
      final d = m.start.addDays((day > m.length ? m.length : day) - 1);
      if (d.isBefore(from) || d.isAfter(to) || d.isBefore(start.date)) continue;
      final o = CivilDateTime(d, start.time);
      if (o.compareTo(start) < 0 || exdates.contains(o)) continue;
      out.add(o);
      if (out.length >= limit) break;
    }
    return out;
  }
}

/// "Sau khi hoàn thành N ngày": không phải lịch cố định, lần sau tính từ ngày hoàn thành.
class AfterCompletion extends Recurrence {
  const AfterCompletion(this.intervalDays) : assert(intervalDays > 0);
  final int intervalDays;

  CivilDateTime nextFromCompletion(CivilDate completedOn, CivilTime? time) =>
      CivilDateTime(completedOn.addDays(intervalDays), time);

  /// Chỉ có lần đầu ([start]); các lần sau phụ thuộc ngày hoàn thành.
  @override
  List<CivilDateTime> between(CivilDateTime start, CivilDate from, CivilDate to,
          {Set<CivilDateTime> exdates = const {}, int limit = 1000}) =>
      !start.date.isBefore(from) && !start.date.isAfter(to) && !exdates.contains(start) ? [start] : const [];
}
