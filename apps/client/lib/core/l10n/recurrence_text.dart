import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

const _byday = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// Mô tả ngắn một quy tắc lặp (hàng `recurrences`: kind + rrule/calendar) cho chip và màn chi tiết.
/// Tên thứ lấy từ CLDR (DateFormat.E), không tự dịch.
String describeRecurrence(BuildContext context, Map<String, Object?> r) {
  final l = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  if (r['kind'] == 'calendar') {
    final c = (r['calendar']! as Map).cast<String, Object?>();
    final day = c['day']! as int, month = c['month'] as int?;
    return month == null ? l.recurLunarMonthly(day) : l.recurLunarYearly(day, month);
  }
  if (r['kind'] == 'after_completion') return l.recurCustom;
  final parts = <String, String>{
    for (final p in (r['rrule'] as String? ?? '').split(';'))
      if (p.contains('=')) p.split('=').first.toUpperCase(): p.split('=').last.toUpperCase(),
  };
  final n = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
  switch (parts['FREQ']) {
    case 'HOURLY':
      return l.recurEveryNHours(n);
    case 'DAILY':
      return l.recurEveryNDays(n);
    case 'WEEKLY':
      final days = (parts['BYDAY'] ?? '').split(',').where(_byday.contains).toList();
      if (days.isEmpty) return l.recurEveryNWeeks(n);
      if (n == 1 && days.toSet().containsAll(const ['MO', 'TU', 'WE', 'TH', 'FR']) && days.length == 5) return l.recurWeekdays;
      // 7/12/2026 là thứ Hai: cộng chỉ số thứ để lấy tên thứ theo locale.
      final names = [for (final d in days) DateFormat.E(locale).format(DateTime(2026, 12, 7 + _byday.indexOf(d)))];
      return l.recurWeeklyOn(n, names.join(', '));
    case 'MONTHLY':
      final day = int.tryParse(parts['BYMONTHDAY'] ?? '');
      return day != null && day > 0 && n == 1 ? l.recurMonthlyOnDay(day) : l.recurEveryNMonths(n);
    case 'YEARLY':
      return l.recurEveryNYears(n);
    default:
      return l.recurCustom;
  }
}
