import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../items/item_tile.dart';
import '../items/schedule_editor.dart' show lunarSystemForLanguage;

/// Lịch tháng (UX §2.6): chấm ở ngày có item, ngày âm nhỏ dưới ngày dương (ngôn ngữ có hệ âm lịch), ngày nghỉ lễ của vùng máy
/// (ADR-017) tô màu. Chạm ngày → ngày lễ + item của ngày đó.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CivilDate? _month;
  CivilDate? _selected;

  CivilDate get _today => CivilDate.of(ref.read(nowProvider)());

  void _go(int months) => setState(() {
        _month = (_month ?? CivilDate(_today.year, _today.month, 1)).addMonths(months);
        _selected = null;
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = _today;
    final month = _month ?? CivilDate(today.year, today.month, 1);
    final selected = _selected ?? (month.year == today.year && month.month == today.month ? today : month);
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = CN
    // Lưới 6 tuần bắt đầu ở ngày đầu tuần theo locale.
    final lead = (month.weekday % 7 - firstDay) % 7;
    final gridStart = month.addDays(-lead);
    final gridEnd = gridStart.addDays(41);
    final counts = ref.watch(calendarCountsProvider('${gridStart.toIso()}|${gridEnd.toIso()}')).value ?? const {};
    final holidays = ref.watch(holidayCalendarProvider).value;
    final lunarSystem = lunarSystemForLanguage(Localizations.localeOf(context).languageCode);
    final lunar = lunarSystem == null ? null : LunarCalendar(lunarSystem);
    final isCurrentMonth = month.year == today.year && month.month == today.month;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMM(locale).format(DateTime(month.year, month.month))),
        actions: [
          if (!isCurrentMonth || _selected != null)
            IconButton(
              key: const Key('calendarToday'),
              tooltip: l.navToday,
              icon: const Icon(Icons.today_outlined),
              onPressed: () => setState(() {
                _month = null;
                _selected = null;
              }),
            ),
          IconButton(key: const Key('calendarPrev'), tooltip: l.calendarPrevMonth, icon: const Icon(Icons.chevron_left), onPressed: () => _go(-1)),
          IconButton(key: const Key('calendarNext'), tooltip: l.calendarNextMonth, icon: const Icon(Icons.chevron_right), onPressed: () => _go(1)),
        ],
      ),
      body: Column(
        children: [
          _weekdayHeader(context, firstDay),
          for (var w = 0; w < 6; w++)
            Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: _DayCell(
                      date: gridStart.addDays(w * 7 + d),
                      inMonth: gridStart.addDays(w * 7 + d).month == month.month,
                      isToday: gridStart.addDays(w * 7 + d) == today,
                      isSelected: gridStart.addDays(w * 7 + d) == selected,
                      count: counts[gridStart.addDays(w * 7 + d).toIso()] ?? 0,
                      holidays: holidays?.on(gridStart.addDays(w * 7 + d)) ?? const [],
                      lunar: lunar?.fromSolar(gridStart.addDays(w * 7 + d)),
                      onTap: (date) => setState(() {
                        _selected = date;
                        if (date.month != month.month) _month = CivilDate(date.year, date.month, 1);
                      }),
                    ),
                  ),
              ],
            ),
          const Divider(height: 1),
          Expanded(child: _DayDetails(date: selected, holidays: holidays?.on(selected) ?? const [])),
        ],
      ),
    );
  }

  Widget _weekdayHeader(BuildContext context, int firstDay) {
    final names = MaterialLocalizations.of(context).narrowWeekdays; // bắt đầu từ CN
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: Tokens.space1),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(names[(firstDay + i) % 7], textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.count,
    required this.holidays,
    required this.lunar,
    required this.onTap,
  });

  final CivilDate date;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final int count;
  final List<Holiday> holidays;
  final LunarDate? lunar;
  final ValueChanged<CivilDate> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final lang = Localizations.localeOf(context).languageCode;
    final dayOff = holidays.any((h) => h.dayOff);
    final local = DateTime(date.year, date.month, date.day);
    final number = NumberFormat.decimalPattern(locale);
    final lunarText = lunar == null
        ? null
        : (lunar!.day == 1 ? l.calendarLunarShort(number.format(lunar!.day), number.format(lunar!.month)) : number.format(lunar!.day));
    var color = dayOff ? scheme.error : scheme.onSurface;
    if (!inMonth) color = color.withValues(alpha: 0.38);
    final label = [
      DateFormat.yMMMMEEEEd(locale).format(local),
      for (final h in holidays) h.name(lang),
      if (lunar != null) l.calendarLunarDate(number.format(lunar!.day), number.format(lunar!.month)),
      if (count > 0) l.calendarItemCount(count),
    ].join(', ');
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: Key('calendarDay-${date.toIso()}'),
        onTap: () => onTap(date),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? scheme.primaryContainer : null,
                  border: isToday ? Border.all(color: scheme.primary) : null,
                ),
                child: Text(DateFormat.d(locale).format(local), style: theme.textTheme.bodyMedium?.copyWith(color: color)),
              ),
              if (lunarText != null)
                Text(lunarText, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: color.withValues(alpha: 0.7))),
              SizedBox(
                height: 6,
                child: count > 0 ? Icon(Icons.circle, size: 5, color: inMonth ? scheme.primary : scheme.primary.withValues(alpha: 0.38)) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ngày lễ + item của ngày đang chọn.
class _DayDetails extends ConsumerWidget {
  const _DayDetails({required this.date, required this.holidays});
  final CivilDate date;
  final List<Holiday> holidays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final sections = ref.watch(daySectionsProvider(date.toIso())).value;
    final items = [...?sections?.today, ...?sections?.doneToday];
    return ListView(
      key: const Key('calendarDayList'),
      children: [
        for (final h in holidays)
          ListTile(
            key: Key('calendarHoliday-${h.id}'),
            leading: Icon(Icons.celebration_outlined, color: h.dayOff ? Theme.of(context).colorScheme.error : null),
            title: Text(h.name(lang)),
            subtitle: h.dayOff ? Text(h.substitute ? l.calendarSubstituteDay : l.calendarDayOff) : null,
          ),
        for (final i in items) ItemTile(key: ValueKey(i.rowKey), item: i),
        if (holidays.isEmpty && items.isEmpty && sections != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Tokens.space6),
            child: EmptyState(icon: Icons.event_available_outlined, title: l.calendarDayEmpty),
          ),
      ],
    );
  }
}
