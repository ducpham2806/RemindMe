import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';

import '../../core/l10n/formatters.dart';
import '../../core/l10n/recurrence_text.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/choice_buttons.dart';
import '../../l10n/app_localizations.dart';
import '../common/text_prompt.dart';
import 'date_time_sheet.dart';
import 'lunar_repeat_sheet.dart';

const byday = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// Quy tắc lặp đã chọn (null = không lặp) và thời điểm bắt đầu mới nếu sheet đổi nó (lặp âm lịch dời về lần tới).
typedef RepeatPick = ({Map<String, Object?>? rule, CivilDateTime? start});

/// "Ngày làm việc" (US-11): các thứ không phải cuối tuần của [region] (CLDR weekData) + `workdays_region` để bỏ ngày nghỉ lễ
/// (vùng chưa có gói ngày lễ thì chỉ bỏ cuối tuần, có gói rồi thì tự áp dụng).
Map<String, Object?> workdaysRule(String? region) {
  final weekend = weekendDays(region);
  final days = [for (var d = DateTime.monday; d <= DateTime.sunday; d++) if (!weekend.contains(d)) byday[d - 1]];
  return {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=${days.join(',')}', 'workdays_region': ?region?.toUpperCase()};
}

/// Phần RRULE (`KEY=VALUE`), giữ thứ tự.
Map<String, String> rruleParts(String rrule) => {
      for (final p in rrule.split(';'))
        if (p.contains('=')) p.split('=').first.toUpperCase(): p.split('=').sublist(1).join('='),
    };

String _join(Map<String, String> parts) => [for (final e in parts.entries) '${e.key}=${e.value}'].join(';');

/// Khóa so sánh 2 quy tắc, bỏ phần kết thúc (UNTIL/COUNT).
String _key(Map<String, Object?>? r) {
  if (r == null) return '';
  final parts = rruleParts(r['rrule'] as String? ?? '')
    ..remove('UNTIL')
    ..remove('COUNT');
  return '${r['kind']}|${_join(parts)}|${jsonEncode(r['calendar'])}|${r['workdays_region']}';
}

/// Lặp lại (Figma 06): các kiểu thường dùng, Âm lịch (07), Tùy chỉnh, Kết thúc; áp dụng bằng nút dưới.
Future<RepeatPick?> showRepeatSheet(
  BuildContext context, {
  required String title,
  required CivilDate date,
  required CivilTime? time,
  required Map<String, Object?>? current,
  required String? region,
  required LunarSystem? lunarSystem,
  required CivilDate today,
  required String tz,
  required DateTime now,
}) =>
    showAppSheet<RepeatPick>(
      context,
      (_) => _RepeatSheet(
        title: title,
        date: date,
        time: time,
        current: current,
        region: region,
        lunarSystem: lunarSystem,
        today: today,
        tz: tz,
        now: now,
      ),
    );

class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({
    required this.title,
    required this.date,
    required this.time,
    required this.current,
    required this.region,
    required this.lunarSystem,
    required this.today,
    required this.tz,
    required this.now,
  });
  final String title;
  final CivilDate date, today;
  final CivilTime? time;
  final Map<String, Object?>? current;
  final String? region;
  final LunarSystem? lunarSystem;
  final String tz;
  final DateTime now;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  late Map<String, Object?>? _rule = widget.current == null
      ? null
      : {
          for (final k in const ['kind', 'rrule', 'calendar', 'workdays_region', 'interval_days'])
            if (widget.current![k] != null) k: widget.current![k],
        };
  CivilDateTime? _start;

  List<(String, String, String?, Map<String, Object?>?)> _presets(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final d = widget.date;
    return [
      ('none', l.recurNone, null, null),
      ('daily', l.repeatDaily, widget.time == null ? l.repeatDailyHint : l.repeatDailyAt(fmt.clock(widget.time!)), {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}),
      ('workdays', l.repeatWorkdays, l.repeatWorkdaysHint, workdaysRule(widget.region)),
      ('weekly', l.repeatWeekly, fmt.weekdayName(d.weekday), {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=${byday[d.weekday - 1]}'}),
      ('monthly', l.repeatMonthly, l.repeatMonthlyHint(d.day), {'kind': 'rrule', 'rrule': 'FREQ=MONTHLY;BYMONTHDAY=${d.day}'}),
      ('yearly', l.repeatYearly, DateFormat.MMMMd(locale).format(DateTime(d.year, d.month, d.day)), {'kind': 'rrule', 'rrule': 'FREQ=YEARLY'}),
    ];
  }

  /// Giữ phần kết thúc đang chọn khi đổi kiểu lặp.
  void _choose(Map<String, Object?>? r) => setState(() {
        final end = _rule?['kind'] == 'rrule' ? rruleParts(_rule!['rrule']! as String) : const <String, String>{};
        var next = r;
        if (next != null && next['kind'] == 'rrule') {
          final parts = rruleParts(next['rrule']! as String);
          for (final k in const ['UNTIL', 'COUNT']) {
            if (end[k] != null && parts[k] == null) parts[k] = end[k]!;
          }
          next = {...next, 'rrule': _join(parts)};
        }
        _rule = next;
        _start = null;
      });

  Future<void> _lunar() async {
    final picked = await showLunarRepeatSheet(
      context,
      system: widget.lunarSystem!,
      title: widget.title,
      date: widget.date,
      time: widget.time,
      current: _rule?['kind'] == 'calendar' ? _rule : null,
      today: widget.today,
    );
    if (picked != null) {
      setState(() {
        _rule = picked.rule;
        _start = picked.start;
      });
    }
  }

  Future<void> _custom() async {
    final picked = await showCustomRepeatSheet(context, date: widget.date, current: _rule);
    if (picked != null) _choose(picked);
  }

  Future<void> _pickEnd() async {
    final l = AppLocalizations.of(context);
    final parts = rruleParts(_rule!['rrule']! as String);
    final choice = await showAppSheet<String>(
      context,
      (context) => AppSheet(
        title: l.repeatEndTitle,
        children: [
          for (final (v, label) in [('never', l.repeatEndNever), ('until', l.repeatEndOnDate), ('count', l.repeatEndAfterCount)])
            SheetOption(
              key: Key('repeatEnd-$v'),
              icon: v == 'until' ? AppIcons.calendar : AppIcons.repeat,
              title: label,
              selected: switch (v) { 'until' => parts['UNTIL'] != null, 'count' => parts['COUNT'] != null, _ => parts['UNTIL'] == null && parts['COUNT'] == null },
              onTap: () => Navigator.of(context).pop(v),
            ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    final until = untilDate(parts) ?? widget.date.addDays(30);
    parts
      ..remove('UNTIL')
      ..remove('COUNT');
    if (choice == 'until') {
      final picked = await showDateTimeSheet(context,
          today: widget.today, tz: widget.tz, now: widget.now, date: until, allowNoTime: true, firstDate: widget.date);
      if (picked == null) return;
      final d = picked.date;
      parts['UNTIL'] = '${d.toIso().replaceAll('-', '')}T235959Z';
    } else if (choice == 'count') {
      if (!mounted) return;
      final text = await askText(context, title: l.repeatEndCountPrompt, initial: '10', fieldKey: const Key('repeatEndCount'), keyboardType: TextInputType.number);
      final n = int.tryParse(text ?? '');
      if (n == null || n < 1) return;
      parts['COUNT'] = '$n';
    }
    setState(() => _rule = {..._rule!, 'rrule': _join(parts)});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final presets = _presets(context);
    final selectedKey = _key(_rule);
    final preset = presets.where((p) => _key(p.$4) == selectedKey).firstOrNull;
    final selectedName = preset?.$2 ?? (_rule == null ? l.recurNone : describeRecurrence(context, _rule!));
    final isLunar = _rule?['kind'] == 'calendar';
    final parts = _rule?['kind'] == 'rrule' ? rruleParts(_rule!['rrule']! as String) : null;
    final whenText = [fmt.monthDay(widget.date), if (widget.time != null) fmt.clock(widget.time!)].join(', ');
    return AppSheet(
      title: l.itemRepeatLabel,
      primaryLabel: l.repeatApply(selectedName),
      primaryKey: const Key('repeatApply'),
      onPrimary: () => Navigator.of(context).pop<RepeatPick>((rule: _rule, start: _start)),
      children: [
        Text([widget.title, whenText].join(' · '), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: scheme.onSurfaceVariant)),
        for (final (id, name, hint, rule) in presets)
          SheetOption(
            key: Key('repeat-$id'),
            icon: AppIcons.repeat,
            title: name,
            subtitle: hint,
            selected: _key(rule) == selectedKey,
            onTap: () => _choose(rule),
          ),
        if (preset == null && _rule != null)
          SheetOption(
            key: const Key('repeat-current'),
            icon: isLunar ? AppIcons.moon : AppIcons.repeat,
            title: describeRecurrence(context, _rule!),
            subtitle: isLunar ? l.repeatLunar : l.repeatCustom,
            selected: true,
            accent: isLunar ? colors.lunar : null,
            accentContainer: isLunar ? colors.lunarContainer : null,
          ),
        Row(
          children: [
            if (widget.lunarSystem != null) ...[
              Expanded(child: _smallButton(context, const Key('repeatLunar'), AppIcons.moon, colors.lunar, l.repeatLunar, _lunar)),
              const SizedBox(width: Tokens.space2),
            ],
            Expanded(child: _smallButton(context, const Key('repeatCustom'), AppIcons.calendar, scheme.primary, l.repeatCustom, _custom)),
          ],
        ),
        if (parts != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('repeatEnd'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36), foregroundColor: scheme.onSurfaceVariant),
              onPressed: _pickEnd,
              child: Text(l.repeatEnds(_endText(context, parts)), style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w400)),
            ),
          ),
      ],
    );
  }

  Widget _smallButton(BuildContext context, Key key, AppIcons icon, Color color, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: key,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Tokens.space3),
          child: Row(
            children: [
              AppIcon(icon, size: 19, color: color),
              const SizedBox(width: Tokens.space2),
              Expanded(child: Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface))),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Không bao giờ" / "Vào 31/12/2026" / "Sau 10 lần".
String _endText(BuildContext context, Map<String, String> parts) {
  final l = AppLocalizations.of(context);
  final until = untilDate(parts);
  if (until != null) return l.repeatEndOn(Fmt.of(context).numericDate(DateTime(until.year, until.month, until.day)));
  final count = int.tryParse(parts['COUNT'] ?? '');
  if (count != null) return l.repeatEndAfter(count);
  return l.repeatEndNever;
}

/// Ngày của `UNTIL` (dạng `YYYYMMDD` hoặc `YYYYMMDDTHHMMSSZ`).
CivilDate? untilDate(Map<String, String> parts) {
  final u = parts['UNTIL'];
  if (u == null || u.length < 8) return null;
  return CivilDate(int.parse(u.substring(0, 4)), int.parse(u.substring(4, 6)), int.parse(u.substring(6, 8)));
}

/// Lặp tùy chỉnh: mỗi N ngày/tuần/tháng/năm, các thứ trong tuần khi theo tuần. Trả quy tắc RRULE.
Future<Map<String, Object?>?> showCustomRepeatSheet(BuildContext context, {required CivilDate date, Map<String, Object?>? current}) =>
    showAppSheet<Map<String, Object?>>(context, (_) => _CustomSheet(date: date, current: current));

class _CustomSheet extends StatefulWidget {
  const _CustomSheet({required this.date, required this.current});
  final CivilDate date;
  final Map<String, Object?>? current;

  @override
  State<_CustomSheet> createState() => _CustomSheetState();
}

class _CustomSheetState extends State<_CustomSheet> {
  String _freq = 'WEEKLY';
  int _interval = 1;
  late Set<String> _days = {byday[widget.date.weekday - 1]};
  Map<String, String> _end = const {};

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    if (c != null && c['kind'] == 'rrule' && c['workdays_region'] == null) {
      final p = rruleParts(c['rrule']! as String);
      if (const ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'].contains(p['FREQ'])) _freq = p['FREQ']!;
      _interval = int.tryParse(p['INTERVAL'] ?? '') ?? 1;
      final days = (p['BYDAY'] ?? '').split(',').where(byday.contains).toSet();
      if (days.isNotEmpty) _days = days;
      _end = {for (final k in const ['UNTIL', 'COUNT']) if (p[k] != null) k: p[k]!};
    }
  }

  Map<String, Object?> get _rule {
    final parts = <String, String>{
      'FREQ': _freq,
      if (_interval > 1) 'INTERVAL': '$_interval',
      if (_freq == 'WEEKLY') 'BYDAY': [for (final d in byday) if (_days.contains(d)) d].join(','),
      if (_freq == 'MONTHLY') 'BYMONTHDAY': '${widget.date.day}',
      ..._end,
    };
    return {'kind': 'rrule', 'rrule': _join(parts)};
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ml = MaterialLocalizations.of(context);
    final first = ml.firstDayOfWeekIndex;
    final rule = _rule;
    return AppSheet(
      title: l.repeatCustomTitle,
      primaryLabel: l.repeatApply(describeRecurrence(context, rule)),
      primaryKey: const Key('customApply'),
      onPrimary: () => Navigator.of(context).pop(rule),
      children: [
        ChoiceButtons(
          keyPrefix: 'customFreq',
          value: _freq,
          options: [('DAILY', l.repeatUnitDay), ('WEEKLY', l.repeatUnitWeek), ('MONTHLY', l.repeatUnitMonth), ('YEARLY', l.repeatUnitYear)],
          onChanged: (v) => setState(() => _freq = v),
        ),
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, Tokens.space1, Tokens.space1, Tokens.space1),
          decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(child: Text(l.repeatEvery, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500))),
              IconButton(
                key: const Key('customMinus'),
                tooltip: l.repeatDecrease,
                onPressed: _interval > 1 ? () => setState(() => _interval--) : null,
                icon: const Icon(Icons.remove),
              ),
              Text(NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag()).format(_interval),
                  key: const Key('customInterval'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                key: const Key('customPlus'),
                tooltip: l.repeatIncrease,
                onPressed: _interval < 99 ? () => setState(() => _interval++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        if (_freq == 'WEEKLY')
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(child: _dayToggle(context, byday[(first + i + 6) % 7], ml.narrowWeekdays[(first + i) % 7])),
            ],
          ),
        Text(describeRecurrence(context, rule), key: const Key('customPreview'), style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _dayToggle(BuildContext context, String code, String label) {
    final scheme = Theme.of(context).colorScheme;
    final on = _days.contains(code);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
      child: Semantics(
        selected: on,
        button: true,
        label: Fmt.of(context).weekdayName(byday.indexOf(code) + 1),
        excludeSemantics: true,
        child: Material(
          color: on ? scheme.primary : scheme.surfaceContainerLowest,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('customDay-$code'),
            onTap: () => setState(() {
              if (on && _days.length > 1) {
                _days = {..._days}..remove(code);
              } else if (!on) {
                _days = {..._days, code};
              }
            }),
            child: AspectRatio(
              aspectRatio: 1,
              child: Center(
                child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: on ? scheme.onPrimary : scheme.onSurfaceVariant)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
