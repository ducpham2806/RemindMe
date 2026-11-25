import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import 'date_time_sheet.dart';

/// Giờ của lựa chọn "Tối nay" / "Sáng mai" (giờ tường ở múi giờ của máy). Mặc định sản phẩm, chưa có cài đặt riêng.
const snoozeEveningHour = 20, snoozeMorningHour = 8;

/// Hoãn nhắc (Figma 08): 10 phút, 30 phút, 1 giờ, tối nay, sáng mai hoặc chọn ngày giờ. Chỉ dời lần nhắc này
/// (`reminders.snoozed_until`), lịch lặp giữ nguyên. Trả thời điểm UTC hoãn tới, null nếu đóng.
Future<DateTime?> showSnoozeSheet(
  BuildContext context, {
  required String title,
  required String? when,
  required DateTime now,
  required String tz,
  String? region,
}) =>
    showAppSheet<DateTime>(context, (_) => _SnoozeSheet(title: title, when: when, now: now, tz: tz, region: region));

class _SnoozeSheet extends StatefulWidget {
  const _SnoozeSheet({required this.title, required this.when, required this.now, required this.tz, required this.region});
  final String title;
  final String? when;
  final DateTime now;
  final String tz;
  final String? region;

  @override
  State<_SnoozeSheet> createState() => _SnoozeSheetState();
}

class _SnoozeSheetState extends State<_SnoozeSheet> {
  int _selected = 0;
  DateTime? _custom;

  List<(String, String, DateTime)> _options(AppLocalizations l) {
    final now = widget.now.toUtc();
    final wall = TimeZones.toWall(now, widget.tz);
    DateTime at(CivilDate d, int hour) => TimeZones.toUtc(CivilDateTime(d, CivilTime(hour)), widget.tz).utc;
    final evening = at(wall.date, snoozeEveningHour);
    return [
      ('10m', l.snoozeMinutes(10), now.add(const Duration(minutes: 10))),
      ('30m', l.snoozeMinutes(30), now.add(const Duration(minutes: 30))),
      ('1h', l.snoozeHours(1), now.add(const Duration(hours: 1))),
      // Tối nay chỉ có khi còn hơn 1 giờ nữa mới tới giờ tối.
      if (evening.isAfter(now.add(const Duration(hours: 1)))) ('evening', l.snoozeTonight, evening),
      ('morning', l.snoozeTomorrowMorning, at(wall.date.addDays(1), snoozeMorningHour)),
    ];
  }

  /// Giờ (cùng ngày) hoặc ngày + giờ, theo múi giờ của máy.
  String _label(DateTime utc) {
    final fmt = Fmt.of(context);
    final w = TimeZones.toWall(utc, widget.tz);
    final today = TimeZones.toWall(widget.now.toUtc(), widget.tz).date;
    return fmt.civil(w, today: today);
  }

  Future<void> _pick() async {
    final now = widget.now.toUtc();
    final wall = TimeZones.toWall(now, widget.tz);
    final picked = await showDateTimeSheet(context,
        today: wall.date, tz: widget.tz, now: widget.now, region: widget.region, requireTime: true, firstDate: wall.date,
        date: wall.date, time: CivilTime(wall.time!.hour, wall.time!.minute).addMinutesClamped(60));
    if (picked == null || picked.time == null) return;
    final utc = TimeZones.toUtc(CivilDateTime(picked.date, picked.time), widget.tz).utc;
    if (!utc.isAfter(now)) return;
    setState(() {
      _custom = utc;
      _selected = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final options = _options(l);
    final target = _selected < 0 ? _custom! : options[_selected.clamp(0, options.length - 1)].$3;
    return AppSheet(
      title: l.snoozeTitle,
      primaryIcon: AppIcons.clock,
      primaryLabel: l.snoozeApply(_label(target)),
      primaryKey: const Key('snoozeApply'),
      onPrimary: () => Navigator.of(context).pop(target),
      children: [
        Container(
          padding: const EdgeInsetsDirectional.all(14),
          decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              AppIcon(AppIcons.bell, size: 22, color: scheme.primary),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                    if (widget.when != null)
                      Text(widget.when!, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (id, name, at)) in options.indexed)
              SheetOption(
                key: Key('snooze-$id'),
                icon: AppIcons.clock,
                title: name,
                trailing: _label(at),
                selected: i == _selected,
                filled: false,
                onTap: () => setState(() => _selected = i),
              ),
            SheetOption(
              key: const Key('snooze-pick'),
              icon: AppIcons.calendar,
              title: l.snoozePick,
              trailing: _custom == null ? null : _label(_custom!),
              selected: _selected < 0,
              filled: false,
              onTap: _pick,
            ),
          ],
        ),
        Text(l.snoozeNote, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

extension on CivilTime {
  /// Cộng phút, không vượt quá 23:59 (giờ gợi ý ban đầu khi chọn ngày giờ hoãn).
  CivilTime addMinutesClamped(int m) {
    final total = (hour * 60 + minute + m).clamp(0, 23 * 60 + 59);
    return CivilTime(total ~/ 60, total % 60);
  }
}

/// Hoãn nhắc của [item] (nút ở chi tiết, vuốt trái ở danh sách): mở [showSnoozeSheet], ghi `snoozed_until` vào nhắc
/// [reminderId] (mặc định nhắc đầu tiên); việc chưa có nhắc thì thêm nhắc tuyệt đối vào giờ hoãn. Báo bằng snackbar.
Future<void> snoozeItem(BuildContext context, WidgetRef ref, {required ItemView item, String? reminderId, DateTime? occurrence}) async {
  final l = AppLocalizations.of(context);
  final fmt = Fmt.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final repo = ref.read(itemsRepositoryProvider);
  final tz = ref.read(deviceTimeZoneProvider);
  final now = ref.read(nowProvider)();
  final today = TimeZones.toWall(now.toUtc(), tz).date;
  final at = occurrence ?? item.occurrenceAt ?? item.startsAt;
  final until = await showSnoozeSheet(context,
      title: item.title,
      when: at == null ? null : fmt.civil(TimeZones.toWall(at, tz), today: today),
      now: now,
      tz: tz,
      region: ref.read(holidayRegionProvider).value ?? ref.read(deviceRegionProvider));
  if (until == null) return;
  final reminders = await repo.remindersOf(item.id);
  final target = reminders.where((r) => r.id == reminderId).firstOrNull ?? reminders.firstOrNull;
  if (target == null) {
    await repo.addReminderAt(item.id, until);
  } else {
    await repo.snooze(target.id, until: until);
  }
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l.snoozeDone(fmt.civil(TimeZones.toWall(until, tz), today: today)))));
}
