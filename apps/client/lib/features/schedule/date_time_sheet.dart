import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../l10n/app_localizations.dart';

/// Ngày + giờ (giờ null = cả ngày) chọn ở [showDateTimeSheet].
typedef DateTimePick = ({CivilDate date, CivilTime? time});

/// Ngày & giờ (Figma 05): chọn nhanh Hôm nay / Ngày mai / Cuối tuần, lịch tháng (ngày đầu tuần theo locale), giờ, múi giờ.
/// [allowNoTime]: cho bỏ giờ (việc cả ngày). [requireTime]: bắt buộc có giờ (hoãn nhắc). Trả null nếu đóng.
Future<DateTimePick?> showDateTimeSheet(
  BuildContext context, {
  required CivilDate today,
  required String tz,
  required DateTime now,
  String? region,
  CivilDate? date,
  CivilTime? time,
  bool allowNoTime = true,
  bool requireTime = false,
  CivilDate? firstDate,
}) =>
    showAppSheet<DateTimePick>(
      context,
      (_) => _DateTimeSheet(
        today: today,
        tz: tz,
        now: now,
        region: region,
        initialDate: date ?? today,
        initialTime: time ?? (requireTime ? CivilTime(9) : null),
        allowNoTime: allowNoTime && !requireTime,
        firstDate: firstDate,
      ),
    );

class _DateTimeSheet extends StatefulWidget {
  const _DateTimeSheet({
    required this.today,
    required this.tz,
    required this.now,
    required this.region,
    required this.initialDate,
    required this.initialTime,
    required this.allowNoTime,
    required this.firstDate,
  });
  final CivilDate today, initialDate;
  final CivilDate? firstDate;
  final String tz;
  final DateTime now;
  final String? region;
  final CivilTime? initialTime;
  final bool allowNoTime;

  @override
  State<_DateTimeSheet> createState() => _DateTimeSheetState();
}

class _DateTimeSheetState extends State<_DateTimeSheet> {
  late CivilDate _date = widget.initialDate;
  late CivilTime? _time = widget.initialTime;
  late CivilDate _month = CivilDate(widget.initialDate.year, widget.initialDate.month, 1);

  /// Ngày cuối tuần gần nhất sau hôm nay (cuối tuần theo vùng, CLDR weekData).
  CivilDate get _weekend {
    final days = weekendDays(widget.region);
    var d = widget.today.addDays(1);
    for (var i = 0; i < 7 && !days.contains(d.weekday); i++) {
      d = d.addDays(1);
    }
    return d;
  }

  void _select(CivilDate d) => setState(() {
        _date = d;
        _month = CivilDate(d.year, d.month, 1);
      });

  void _shiftMonth(int delta) => setState(() {
        final m = _month.month - 1 + delta;
        _month = CivilDate(_month.year + (m / 12).floor(), m % 12 + 1, 1);
      });

  Future<void> _pickTime() async {
    final t = _time ?? CivilTime(9);
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: t.hour, minute: t.minute));
    if (picked != null) setState(() => _time = CivilTime(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tomorrow = widget.today.addDays(1);
    final weekend = _weekend;
    final quick = <(String, CivilDate)>[('today', widget.today), ('tomorrow', tomorrow), ('weekend', weekend)];
    final selectedQuick = quick.where((q) => q.$2 == _date).firstOrNull?.$1;
    final summary = [fmt.monthDay(_date), if (_time != null) fmt.clock(_time!)].join(', ');
    return AppSheet(
      title: l.dtSheetTitle,
      primaryLabel: l.dtConfirm(_time == null ? l.dtConfirmAllDay(fmt.monthDay(_date)) : summary),
      primaryKey: const Key('dtConfirm'),
      onPrimary: () => Navigator.of(context).pop<DateTimePick>((date: _date, time: _time)),
      children: [
        SheetChips(
          keyPrefix: 'dtQuick',
          selected: selectedQuick,
          options: [('today', l.dtQuickToday), ('tomorrow', l.dtQuickTomorrow), ('weekend', l.dtQuickWeekend)],
          onTap: (v) => _select(quick.firstWhere((q) => q.$1 == v).$2),
        ),
        _MonthGrid(
          month: _month,
          selected: _date,
          today: widget.today,
          firstDate: widget.firstDate,
          onSelect: _select,
          onShift: _shiftMonth,
        ),
        Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('dtTime'),
            onTap: _pickTime,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, Tokens.space2, Tokens.space2, Tokens.space2),
              child: Row(
                children: [
                  AppIcon(AppIcons.clock, size: 22, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l.dtTimeLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500))),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(vertical: Tokens.space1, horizontal: Tokens.space1),
                    child: Text(
                      _time == null ? l.itemAddTime : fmt.clock(_time!),
                      key: const Key('dtTimeValue'),
                      style: _time == null
                          ? theme.textTheme.titleSmall?.copyWith(color: scheme.primary)
                          : theme.textTheme.titleLarge?.copyWith(fontSize: 22, height: 32 / 22, fontWeight: FontWeight.w600, color: scheme.primary),
                    ),
                  ),
                  if (widget.allowNoTime && _time != null)
                    IconButton(
                      key: const Key('dtClearTime'),
                      tooltip: l.itemRemoveTime,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _time = null),
                      icon: AppIcon(AppIcons.close, size: 18, color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            AppIcon(AppIcons.globe, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: Tokens.space2),
            Expanded(
              child: Text([widget.tz, utcOffsetLabel(widget.now, widget.tz)].join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Lịch 1 tháng: tiêu đề tháng + nút trước/sau, hàng thứ (tên hẹp CLDR), 6 tuần; ngày ngoài tháng chữ mờ.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.firstDate,
    required this.onSelect,
    required this.onShift,
  });
  final CivilDate month, selected, today;
  final CivilDate? firstDate;
  final ValueChanged<CivilDate> onSelect;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ml = MaterialLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final first = ml.firstDayOfWeekIndex; // 0 = Chủ nhật
    final lead = (month.weekday % 7 - first + 7) % 7;
    final start = month.addDays(-lead);
    final title = toBeginningOfSentenceCase(DateFormat.yMMMM(locale).format(DateTime(month.year, month.month)), locale);
    final disabled = RemindColors.of(context).textDisabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, key: const Key('dtMonth'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            IconButton(
              key: const Key('dtPrevMonth'),
              tooltip: ml.previousMonthTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: () => onShift(-1),
              icon: AppIcon(AppIcons.back, size: 20, color: scheme.onSurface),
            ),
            IconButton(
              key: const Key('dtNextMonth'),
              tooltip: ml.nextMonthTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: () => onShift(1),
              icon: AppIcon(AppIcons.chevron, size: 20, color: scheme.onSurface),
            ),
          ],
        ),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: Center(
                    child: ExcludeSemantics(
                      child: Text(ml.narrowWeekdays[(first + i) % 7],
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: scheme.onSurfaceVariant)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var w = 0; w < 6; w++)
          Row(
            children: [
              for (var i = 0; i < 7; i++) Expanded(child: _day(context, start.addDays(w * 7 + i), disabled)),
            ],
          ),
      ],
    );
  }

  Widget _day(BuildContext context, CivilDate d, Color disabledColor) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inMonth = d.month == month.month;
    final isSelected = d == selected;
    final enabled = firstDate == null || !d.isBefore(firstDate!);
    final color = isSelected
        ? scheme.onPrimary
        : !enabled || !inMonth
            ? disabledColor
            : d == today
                ? scheme.primary
                : scheme.onSurface;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final local = DateTime(d.year, d.month, d.day);
    final label = DateFormat.yMMMMEEEEd(locale).format(local);
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('dtDay-${d.toIso()}'),
          onTap: enabled ? () => onSelect(d) : null,
          child: SizedBox(
            height: 37,
            child: Center(
              child: Text(DateFormat.d(locale).format(local),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: color,
                      fontWeight: isSelected || d == today ? FontWeight.w600 : FontWeight.w400)),
            ),
          ),
        ),
      ),
    );
  }
}
