import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';

import '../../core/l10n/formatters.dart';
import '../../core/l10n/recurrence_text.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'repeat_sheet.dart';

/// Tên hệ âm lịch theo ngôn ngữ giao diện.
String lunarSystemName(AppLocalizations l, LunarSystem s) => switch (s) {
      LunarSystem.vi => l.lunarVi,
      LunarSystem.zh => l.lunarZh,
      LunarSystem.ko => l.lunarKo,
    };

/// Lặp theo âm lịch (Figma 07): mùng 1 / rằm hằng tháng hoặc ngày riêng (giỗ) hằng năm, giờ nhắc, tháng nhuận.
/// Trả quy tắc `calendar` và lần tới tính từ [today] (thời điểm bắt đầu mới của item).
Future<RepeatPick?> showLunarRepeatSheet(
  BuildContext context, {
  required LunarSystem system,
  required String title,
  required CivilDate date,
  required CivilTime? time,
  required Map<String, Object?>? current,
  required CivilDate today,
}) =>
    showAppSheet<RepeatPick>(
      context,
      (_) => _LunarSheet(system: system, title: title, date: date, time: time, current: current, today: today),
    );

class _LunarSheet extends StatefulWidget {
  const _LunarSheet({required this.system, required this.title, required this.date, required this.time, required this.current, required this.today});
  final LunarSystem system;
  final String title;
  final CivilDate date, today;
  final CivilTime? time;
  final Map<String, Object?>? current;

  @override
  State<_LunarSheet> createState() => _LunarSheetState();
}

class _LunarSheetState extends State<_LunarSheet> {
  late int _day;
  /// null = hằng tháng.
  int? _month;
  LeapRule _leap = LeapRule.skip;
  late CivilTime? _time = widget.time;

  @override
  void initState() {
    super.initState();
    final c = (widget.current?['calendar'] as Map?)?.cast<String, Object?>();
    if (c != null && c['system'] == widget.system.wire) {
      _day = c['day']! as int;
      _month = c['month'] as int?;
      _leap = LeapRule.fromWire(c['leap'] as String?);
    } else {
      final lunar = LunarCalendar(widget.system).fromSolar(widget.date);
      _day = lunar.day;
      _month = lunar.month;
    }
  }

  Map<String, Object?> get _rule => {
        'kind': 'calendar',
        'calendar': {'system': widget.system.wire, 'day': _day, 'month': ?_month, if (_leap == LeapRule.both) 'leap': 'both'},
      };

  String get _preset => _month == null && _day == 1
      ? 'first'
      : _month == null && _day == 15
          ? 'full'
          : 'own';

  CivilDateTime? get _next {
    final from = CivilDateTime(widget.today, _time);
    final hits = Recurrence.fromRow(_rule).between(from, widget.today, widget.today.addDays(800), limit: 1);
    return hits.firstOrNull;
  }

  void _setPreset(String p) => setState(() {
        switch (p) {
          case 'first':
            _day = 1;
            _month = null;
          case 'full':
            _day = 15;
            _month = null;
          default:
            final lunar = LunarCalendar(widget.system).fromSolar(widget.date);
            _day = lunar.day;
            _month = lunar.month;
        }
      });

  Future<int?> _pickNumber(String title, int max, int current, {String? note}) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nf = NumberFormat.decimalPattern(locale);
    return showAppSheet<int>(
      context,
      (context) {
        final scheme = Theme.of(context).colorScheme;
        return AppSheet(
          title: title,
          children: [
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Tokens.space2,
              crossAxisSpacing: Tokens.space2,
              children: [
                for (var n = 1; n <= max; n++)
                  Material(
                    color: n == current ? scheme.primary : scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: Key('lunarPick-$n'),
                      onTap: () => Navigator.of(context).pop(n),
                      child: Center(
                        child: Text(nf.format(n),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: n == current ? scheme.onPrimary : scheme.onSurface)),
                      ),
                    ),
                  ),
              ],
            ),
            if (note != null) Text(note, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      },
    );
  }

  Future<T?> _pickOption<T>(String title, List<(T, String, AppIcons)> options, T current) => showAppSheet<T>(
        context,
        (context) => AppSheet(
          title: title,
          children: [
            for (final (i, (v, label, icon)) in options.indexed)
              SheetOption(
                key: Key('lunarOption-$i'),
                icon: icon,
                title: label,
                selected: v == current,
                onTap: () => Navigator.of(context).pop(v),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nf = NumberFormat.decimalPattern(locale);
    final next = _next;
    final small = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant);

    Widget numberCard(Key key, String label, String value, VoidCallback onTap) => Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: key,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(Tokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: small),
                  const SizedBox(height: Tokens.space2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(fontSize: 24, height: 35 / 24, fontWeight: FontWeight.w600)),
                      ),
                      AppIcon(AppIcons.chevronSmall, size: 18, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

    return AppSheet(
      title: l.lunarSheetTitle,
      primaryLabel: l.lunarApply,
      primaryKey: const Key('lunarApply'),
      onPrimary: next == null ? null : () => Navigator.of(context).pop<RepeatPick>((rule: _rule, start: next)),
      children: [
        Container(
          padding: const EdgeInsetsDirectional.all(14),
          decoration: BoxDecoration(color: colors.lunarContainer, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              AppIcon(AppIcons.moon, size: 26, color: colors.lunar),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lunarSystemName(l, widget.system), style: theme.textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: colors.lunar)),
                    const SizedBox(height: 3),
                    Text(l.lunarSheetHint, style: small),
                  ],
                ),
              ),
            ],
          ),
        ),
        SheetChips(
          keyPrefix: 'lunarPreset',
          selected: _preset,
          accent: colors.lunar,
          accentContainer: colors.lunarContainer,
          options: [('first', l.lunarFirstDay), ('full', l.lunarFullMoon), ('own', l.lunarOwnDate)],
          onTap: _setPreset,
        ),
        Text(widget.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 21, height: 30 / 21, fontWeight: FontWeight.w600)),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: numberCard(const Key('lunarDay'), l.lunarDayLabel, nf.format(_day), () async {
                  final n = await _pickNumber(l.lunarDayLabel, 30, _day, note: l.lunarDay30Note);
                  if (n != null) setState(() => _day = n);
                }),
              ),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: numberCard(const Key('lunarMonth'), l.lunarMonthLabel, _month == null ? l.lunarEveryMonth : nf.format(_month), () async {
                  final n = await _pickNumber(l.lunarMonthLabel, 12, _month ?? 0);
                  if (n != null) setState(() => _month = n);
                }),
              ),
            ],
          ),
        ),
        SheetOption(
          key: const Key('lunarFrequency'),
          icon: AppIcons.repeat,
          title: l.lunarFrequency,
          subtitle: _month == null ? l.repeatMonthly : l.repeatYearly,
          onTap: () async {
            final v = await _pickOption(l.lunarFrequency, [(true, l.repeatYearly, AppIcons.repeat), (false, l.repeatMonthly, AppIcons.repeat)], _month != null);
            if (v == null) return;
            setState(() => _month = v ? (_month ?? LunarCalendar(widget.system).fromSolar(widget.date).month) : null);
          },
        ),
        SheetOption(
          key: const Key('lunarTime'),
          icon: AppIcons.clock,
          title: l.dtTimeLabel,
          subtitle: _time == null ? l.itemAllDay : fmt.clock(_time!),
          onTap: () async {
            final t = _time ?? CivilTime(8);
            final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: t.hour, minute: t.minute));
            if (picked != null) setState(() => _time = CivilTime(picked.hour, picked.minute));
          },
        ),
        SheetOption(
          key: const Key('lunarLeap'),
          icon: AppIcons.moon,
          title: l.lunarLeap,
          subtitle: _leap == LeapRule.both ? l.lunarLeapBoth : l.lunarLeapSkip,
          onTap: () async {
            final v = await _pickOption(l.lunarLeap, [(LeapRule.skip, l.lunarLeapSkip, AppIcons.moon), (LeapRule.both, l.lunarLeapBoth, AppIcons.moon)], _leap);
            if (v != null) setState(() => _leap = v);
          },
        ),
        Container(
          key: const Key('lunarSummary'),
          padding: const EdgeInsetsDirectional.all(14),
          decoration: BoxDecoration(color: colors.lunarContainer, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(describeRecurrence(context, _rule), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: colors.lunar)),
              const SizedBox(height: 5),
              Text(
                next == null
                    ? l.lunarNoNext
                    : [l.lunarNext(fmt.date(DateTime(next.date.year, next.date.month, next.date.day))), l.lunarRecalc].join(' '),
                style: small,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
