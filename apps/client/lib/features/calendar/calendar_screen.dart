import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../items/item_tile.dart';
import '../trips/trips_screen.dart' show tripDateRange;

/// Lịch tháng (UX §2.6, Figma 24): thẻ tháng (chấm ở ngày có item, ngày âm khi có hệ lịch phụ, ngày nghỉ lễ tô đỏ, ngày thuộc chuyến đi
/// tô nền travel + chú thích), rồi ngày đang chọn: ngày lễ, lịch hẹn/đặt chỗ (giờ địa phương của từng nơi) và việc.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = _today;
    final month = _month ?? CivilDate(today.year, today.month, 1);
    final selected = _selected ?? (month.year == today.year && month.month == today.month ? today : month);
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = CN
    // Lưới bắt đầu ở ngày đầu tuần theo locale, đủ số tuần của tháng.
    final lead = (month.weekday % 7 - firstDay) % 7;
    final gridStart = month.addDays(-lead);
    final daysInMonth = month.addMonths(1).addDays(-1).day;
    final weeks = ((lead + daysInMonth) / 7).ceil();
    final gridEnd = gridStart.addDays(weeks * 7 - 1);
    final counts = ref.watch(calendarCountsProvider('${gridStart.toIso()}|${gridEnd.toIso()}')).value ?? const {};
    final holidays = ref.watch(holidayCalendarProvider).value;
    final lunarSystem =
        effectiveLunarSystem(ref.watch(calendarSystemSettingProvider).value ?? prefAuto, Localizations.localeOf(context).languageCode);
    final lunar = lunarSystem == null ? null : LunarCalendar(lunarSystem);
    final trips = [
      for (final t in ref.watch(tripsProvider).value ?? const <TripSummary>[])
        if (t.startsOn != null && t.overlaps(gridStart.toIso(), gridEnd.toIso(), slackDays: 0)) t,
    ];
    bool inTrip(CivilDate d) => trips.any((t) => t.overlaps(d.toIso(), d.toIso(), slackDays: 0));
    final isCurrentMonth = month.year == today.year && month.month == today.month;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space2, Tokens.screenMargin, Tokens.space6),
          children: [
            Semantics(header: true, child: Text(l.navCalendar, style: theme.textTheme.headlineLarge)),
            Text(DateFormat.MMMMEEEEd(locale).format(DateTime(selected.year, selected.month, selected.day)), style: theme.textTheme.bodySmall),
            if (!isCurrentMonth || _selected != null) ...[
              const SizedBox(height: Tokens.space3),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Chip(
                  key: const Key('calendarToday'),
                  label: l.navToday,
                  onTap: () => setState(() {
                    _month = null;
                    _selected = null;
                  }),
                ),
              ),
            ],
            const SizedBox(height: Tokens.space4),
            DecoratedBox(
              decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            toBeginningOfSentenceCase(DateFormat.yMMMM(locale).format(DateTime(month.year, month.month)), locale),
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, height: 26 / 18),
                          ),
                        ),
                        IconButton(
                          key: const Key('calendarPrev'),
                          tooltip: l.calendarPrevMonth,
                          visualDensity: VisualDensity.compact,
                          icon: AppIcon(AppIcons.back, color: scheme.onSurfaceVariant),
                          onPressed: () => _go(-1),
                        ),
                        IconButton(
                          key: const Key('calendarNext'),
                          tooltip: l.calendarNextMonth,
                          visualDensity: VisualDensity.compact,
                          icon: AppIcon(AppIcons.chevron, color: scheme.onSurfaceVariant),
                          onPressed: () => _go(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: Tokens.space2),
                    _weekdayHeader(context, firstDay),
                    for (var w = 0; w < weeks; w++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: Tokens.space1),
                        child: Row(
                          children: [
                            for (var d = 0; d < 7; d++)
                              if (gridStart.addDays(w * 7 + d) case final date)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.only(start: d == 0 ? 0 : 2, end: d == 6 ? 0 : 2),
                                    child: _DayCell(
                                      date: date,
                                      inMonth: date.month == month.month,
                                      isToday: date == today,
                                      isSelected: date == selected,
                                      inTrip: inTrip(date),
                                      count: counts[date.toIso()] ?? 0,
                                      holidays: holidays?.on(date) ?? const [],
                                      lunar: lunar?.fromSolar(date),
                                      onTap: (d) => setState(() {
                                        _selected = d;
                                        if (d.month != month.month) _month = CivilDate(d.year, d.month, 1);
                                      }),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    for (final t in trips)
                      Padding(
                        key: Key('calendarTrip-${t.id}'),
                        padding: const EdgeInsetsDirectional.only(top: Tokens.space2),
                        child: Row(
                          children: [
                            Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: RemindColors.of(context).travel)),
                            const SizedBox(width: Tokens.space2),
                            Expanded(
                              child: Text(
                                [t.title ?? l.navTrips, ?tripDateRange(context, t, ref.read(nowProvider)())].join(' · '),
                                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Tokens.space5),
            _DayDetails(date: selected, holidays: holidays?.on(selected) ?? const []),
          ],
        ),
      ),
    );
  }

  Widget _weekdayHeader(BuildContext context, int firstDay) {
    final theme = Theme.of(context);
    final names = MaterialLocalizations.of(context).narrowWeekdays; // bắt đầu từ CN
    return ExcludeSemantics(
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    names[(firstDay + i) % 7],
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, height: 1.5, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chip nhỏ của Figma (Hôm nay): nền thẻ, bo 8, chữ 11/16 primary.
class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Tokens.space2),
          child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
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
    required this.inTrip,
    required this.count,
    required this.holidays,
    required this.lunar,
    required this.onTap,
  });

  final CivilDate date;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool inTrip;
  final int count;
  final List<Holiday> holidays;
  final LunarDate? lunar;
  final ValueChanged<CivilDate> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final lang = Localizations.localeOf(context).languageCode;
    final dayOff = holidays.any((h) => h.dayOff);
    final local = DateTime(date.year, date.month, date.day);
    final number = NumberFormat.decimalPattern(locale);
    final lunarText = lunar == null
        ? null
        : (lunar!.day == 1 ? l.calendarLunarShort(number.format(lunar!.day), number.format(lunar!.month)) : number.format(lunar!.day));
    final color = isSelected
        ? scheme.onPrimary
        : !inMonth
            ? colors.textDisabled
            : dayOff
                ? scheme.error
                : scheme.onSurface;
    final label = [
      DateFormat.yMMMMEEEEd(locale).format(local),
      for (final h in holidays) h.name(lang),
      if (lunar != null) l.calendarLunarDate(number.format(lunar!.day), number.format(lunar!.month)),
      if (count > 0) l.calendarItemCount(count),
    ].join(', ');
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? scheme.primary : (inTrip ? colors.travelContainer : Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: isToday && !isSelected ? BorderSide(color: scheme.primary) : BorderSide.none,
        ),
        child: InkWell(
          key: Key('calendarDay-${date.toIso()}'),
          borderRadius: radius,
          onTap: () => onTap(date),
          // Tối thiểu 44 (Figma), cao thêm khi người dùng phóng chữ.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat.d(locale).format(local),
                  style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
                ),
                if (lunarText != null)
                  Text(lunarText, style: theme.textTheme.labelSmall?.copyWith(fontSize: 8, height: 1.2, color: color.withValues(alpha: 0.7))),
                if (count > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2),
                    child: Icon(Icons.circle, size: 4, color: isSelected ? scheme.onPrimary : colors.travel),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ngày lễ + lịch hẹn/đặt chỗ + việc của ngày đang chọn.
class _DayDetails extends ConsumerWidget {
  const _DayDetails({required this.date, required this.holidays});
  final CivilDate date;
  final List<Holiday> holidays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final sections = ref.watch(daySectionsProvider(date.toIso())).value;
    final items = [...?sections?.today, ...?sections?.doneToday];
    final timed = [for (final i in items) if (i.kind != 'task' && i.startsAt != null && !i.allDay) i];
    final others = [for (final i in items) if (!timed.contains(i)) i];
    final info = ref.watch(bookingInfoProvider(timed.map((i) => i.id).join('|'))).value ?? const {};
    return Column(
      key: const Key('calendarDayList'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(DateFormat.MMMMEEEEd(locale).format(DateTime(date.year, date.month, date.day)), style: theme.textTheme.labelMedium),
              ),
            ),
            if (items.isNotEmpty)
              Text(l.calendarItemCount(items.length),
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: Tokens.space2),
        for (final h in holidays)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Tokens.space2),
            child: Card(
              key: Key('calendarHoliday-${h.id}'),
              child: ListTile(
                leading: Icon(Icons.celebration_outlined, color: h.dayOff ? theme.colorScheme.error : null),
                title: Text(h.name(lang), style: theme.textTheme.titleSmall),
                subtitle: h.dayOff ? Text(h.substitute ? l.calendarSubstituteDay : l.calendarDayOff, style: theme.textTheme.labelSmall) : null,
              ),
            ),
          ),
        for (final i in timed) _AgendaCard(item: i, info: info[i.id]),
        for (final i in others) ItemTile(key: ValueKey(i.rowKey), item: i, inset: false),
        if (timed.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Tokens.space2),
            child: Row(
              children: [
                AppIcon(AppIcons.globe, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: Tokens.space2),
                Expanded(
                  child: Text(l.calendarLocalTimeNote,
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        if (holidays.isEmpty && items.isEmpty && sections != null)
          EmptyState(icon: Icons.event_available_outlined, title: l.calendarDayEmpty),
      ],
    );
  }
}

/// Thẻ lịch hẹn (Figma 24): giờ lớn màu travel theo múi giờ của nơi đó + icon loại, tên, dòng phụ (giờ đến · chuyến), mũi tên.
class _AgendaCard extends ConsumerWidget {
  const _AgendaCard({required this.item, required this.info});
  final ItemView item;
  final ({String? bookingType, String? destinationTz, String? tripTitle})? info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final travel = RemindColors.of(context).travel;
    final deviceTz = ref.watch(deviceTimeZoneProvider);
    // Giờ theo múi giờ của nơi đó (giờ đi theo nơi đi, giờ đến theo nơi đến), không có thì theo máy.
    String hm(DateTime utc, String? tz) {
      final w = TimeZones.toWall(utc, tz != null && TimeZones.isValid(tz) ? tz : deviceTz).time!;
      return MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay(hour: w.hour, minute: w.minute), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    }

    final type = info?.bookingType;
    final Widget icon = switch (type) {
      'flight' => AppIcon(AppIcons.plane, color: travel, size: 20),
      'hotel' => AppIcon(AppIcons.hotel, color: travel, size: 20),
      'train' => Icon(Icons.train_outlined, size: 20, color: travel),
      'bus' => Icon(Icons.directions_bus_outlined, size: 20, color: travel),
      'ferry' => Icon(Icons.directions_boat_outlined, size: 20, color: travel),
      'car_rental' => Icon(Icons.directions_car_outlined, size: 20, color: travel),
      _ => Icon(item.kind == 'appointment' ? Icons.medical_services_outlined : Icons.event_outlined, size: 20, color: travel),
    };
    final sub = [
      if (item.endsAt != null && type != 'hotel') l.calendarArrives(hm(item.endsAt!, info?.destinationTz ?? item.tz)),
      ?info?.tripTitle,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: Tokens.space2),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: Key('calendarAgenda-${item.rowKey}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/item/${item.id}'),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Tokens.space4),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hm(item.startsAt!, item.tz),
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 17, height: 25 / 17, color: travel),
                      ),
                      const SizedBox(height: 5),
                      icon,
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(sub, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.space3),
                AppIcon(AppIcons.chevronSmall, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
