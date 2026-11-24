import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../l10n/app_localizations.dart';

/// Định dạng ngày giờ theo CLDR của locale đang dùng (AGENTS quy tắc 5b). Không ghép chuỗi ngày bằng tay.
class Fmt {
  Fmt._(this._context);
  factory Fmt.of(BuildContext context) => Fmt._(context);
  final BuildContext _context;

  String get _locale => Localizations.localeOf(_context).toLanguageTag();

  /// Giờ theo cài đặt 12/24 giờ của máy.
  String time(DateTime utc) => MaterialLocalizations.of(_context).formatTimeOfDay(
        TimeOfDay.fromDateTime(utc.toLocal()),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(_context),
      );

  /// Ví dụ en: "Tue, Dec 1"; vi: "Th 3, 1 thg 12".
  String dayHeader(DateTime local) => DateFormat.MMMEd(_locale).format(local);

  /// Ngày ngắn, kèm năm nếu khác năm nay.
  String date(DateTime local, {DateTime? now}) {
    final sameYear = local.year == (now ?? DateTime.now()).year;
    return (sameYear ? DateFormat.MMMd(_locale) : DateFormat.yMMMd(_locale)).format(local);
  }

  /// Dòng "khi nào" của 1 item: giờ (hôm nay) hoặc ngày + giờ, "Cả ngày" cho item cả ngày.
  String? when(ItemView i, {required DayWindow today}) {
    final l = AppLocalizations.of(_context);
    if (i.startDate != null && (i.allDay || i.startsAt == null)) {
      final d = DateTime.parse(i.startDate!);
      return i.startDate == today.localDate ? l.itemAllDay : l.itemDateAllDay(date(d));
    }
    final s = i.startsAt;
    if (s == null) return null;
    final sameDay = !s.isBefore(today.startUtc) && s.isBefore(today.endUtc);
    return sameDay ? time(s) : l.itemDateTime(date(s.toLocal()), time(s));
  }

  /// Thời điểm giờ tường từ NLU (chip Quick Add): "Cả ngày" / giờ nếu là hôm nay, kèm ngày nếu khác hôm nay.
  String civil(CivilDateTime w, {required CivilDate today}) {
    final l = AppLocalizations.of(_context);
    final d = DateTime(w.date.year, w.date.month, w.date.day, w.time?.hour ?? 0, w.time?.minute ?? 0);
    final isToday = w.date == today;
    if (w.time == null) return isToday ? l.itemAllDay : l.itemDateAllDay(date(d));
    final t = MaterialLocalizations.of(_context).formatTimeOfDay(TimeOfDay(hour: d.hour, minute: d.minute),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(_context));
    return isToday ? t : l.itemDateTime(date(d), t);
  }
}
