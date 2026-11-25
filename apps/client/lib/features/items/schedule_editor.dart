import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/l10n/formatters.dart';
import '../../core/l10n/recurrence_text.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/setting_row.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

const _byday = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// "Ngày làm việc" (US-11): các thứ không phải cuối tuần của [region] (CLDR weekData) + `workdays_region` để bỏ ngày nghỉ lễ
/// (vùng chưa có gói ngày lễ thì chỉ bỏ cuối tuần, có gói rồi thì tự áp dụng).
Map<String, Object?> workdaysRule(String? region) {
  final weekend = weekendDays(region);
  final days = [for (var d = DateTime.monday; d <= DateTime.sunday; d++) if (!weekend.contains(d)) _byday[d - 1]];
  return {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=${days.join(',')}', 'workdays_region': ?region?.toUpperCase()};
}

/// Thời điểm (ngày, giờ) và lặp lại của item (UX §2.3). Sửa theo múi giờ của máy.
class ScheduleEditor extends ConsumerWidget {
  const ScheduleEditor({super.key, required this.item, this.between});
  final ItemView item;
  /// Hàng chèn giữa Ngày & giờ và Lặp lại (Nhắc, theo thứ tự Figma 04).
  final Widget? between;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final tz = ref.watch(deviceTimeZoneProvider);
    final repo = ref.read(itemsRepositoryProvider);
    final rule = ref.watch(recurrenceProvider(item.id)).value;
    final wall = _wall(item, tz);
    final today = CivilDate.of(ref.watch(nowProvider)());

    Future<void> save({CivilDate? date, CivilTime? time, bool clear = false}) async {
      if (clear) {
        await repo.setSchedule(item.id);
        await repo.setRecurrence(item.id, null);
        return;
      }
      final d = date!;
      final DateTime start;
      if (time == null) {
        await repo.setSchedule(item.id, startDate: d.toIso(), tz: tz);
        start = TimeZones.toUtc(CivilDateTime(d, CivilTime(0)), tz).utc;
      } else {
        start = TimeZones.toUtc(CivilDateTime(d, time), tz).utc;
        await repo.setSchedule(item.id, startsAt: start, tz: tz);
      }
      if (rule != null) await repo.setRecurrence(item.id, rule, start: start);
    }

    Future<void> pickDate() async {
      final initial = wall?.date ?? today;
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(initial.year, initial.month, initial.day),
        firstDate: DateTime(today.year - 5),
        lastDate: DateTime(today.year + 20),
      );
      if (picked != null) await save(date: CivilDate.of(picked), time: wall?.time);
    }

    Future<void> pickTime() async {
      final t = wall?.time;
      final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: t?.hour ?? 9, minute: t?.minute ?? 0));
      if (picked != null) await save(date: wall?.date ?? today, time: CivilTime(picked.hour, picked.minute));
    }

    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurfaceVariant;
    return Column(
      key: const Key('scheduleEditor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingRow(
          icon: AppIcons.calendar,
          label: l.itemDateTimeLabel,
          child: Wrap(
            spacing: Tokens.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SettingValueButton(
                key: const Key('pickDate'),
                label: wall == null ? l.itemAddDate : fmt.date(DateTime(wall.date.year, wall.date.month, wall.date.day)),
                onTap: pickDate,
              ),
              if (wall != null)
                SettingValueButton(
                  key: const Key('pickTime'),
                  label: wall.time == null
                      ? l.itemAddTime
                      : MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: wall.time!.hour, minute: wall.time!.minute),
                          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context)),
                  onTap: pickTime,
                ),
              if (wall?.time != null)
                IconButton(
                  key: const Key('removeTime'),
                  visualDensity: VisualDensity.compact,
                  tooltip: l.itemRemoveTime,
                  icon: Icon(Icons.timer_off_outlined, size: 20, color: iconColor),
                  onPressed: () => save(date: wall!.date),
                ),
              if (wall != null)
                IconButton(
                  key: const Key('removeDate'),
                  visualDensity: VisualDensity.compact,
                  tooltip: l.itemRemoveDate,
                  icon: Icon(Icons.event_busy_outlined, size: 20, color: iconColor),
                  onPressed: () => save(clear: true),
                ),
            ],
          ),
        ),
        ?between,
        SettingRow(
          key: const Key('repeatRow'),
          icon: AppIcons.repeat,
          label: l.itemRepeatLabel,
          value: wall == null ? l.recurNeedsDate : (rule == null ? l.recurNone : describeRecurrence(context, rule)),
          enabled: wall != null,
          onTap: wall == null
              ? null
              : () => _pickRepeat(context,
                  region: ref.read(holidayRegionProvider).value ?? ref.read(deviceRegionProvider),
                  lunarSystem: effectiveLunarSystem(ref.read(calendarSystemSettingProvider).value ?? prefAuto, Localizations.localeOf(context).languageCode),
                  current: rule, date: wall.date, onPick: (r) async {
                    final start = wall.time == null
                        ? TimeZones.toUtc(CivilDateTime(wall.date, CivilTime(0)), tz).utc
                        : TimeZones.toUtc(wall, tz).utc;
                    await repo.setRecurrence(item.id, r, start: start);
                  }),
        ),
      ],
    );
  }

  /// Ngày/giờ tường của item theo múi giờ của máy.
  static CivilDateTime? _wall(ItemView i, String deviceTz) {
    if (i.startsAt != null && !i.allDay) return TimeZones.toWall(i.startsAt!, deviceTz);
    if (i.startDate != null) return CivilDateTime(CivilDate.parse(i.startDate!));
    return null;
  }

  Future<void> _pickRepeat(BuildContext context,
      {required String? region,
      required LunarSystem? lunarSystem,
      required Map<String, Object?>? current, required CivilDate date, required Future<void> Function(Map<String, Object?>?) onPick}) {
    final lunar = lunarSystem == null ? null : LunarCalendar(lunarSystem).fromSolar(date);
    final options = <Map<String, Object?>?>[
      null,
      {'kind': 'rrule', 'rrule': 'FREQ=DAILY'},
      workdaysRule(region),
      {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=${_byday[date.weekday - 1]}'},
      {'kind': 'rrule', 'rrule': 'FREQ=MONTHLY;BYMONTHDAY=${date.day}'},
      {'kind': 'rrule', 'rrule': 'FREQ=YEARLY'},
      if (lunar != null && !lunar.leap) ...[
        {'kind': 'calendar', 'calendar': {'system': lunarSystem!.wire, 'day': lunar.day}},
        {'kind': 'calendar', 'calendar': {'system': lunarSystem.wire, 'month': lunar.month, 'day': lunar.day}},
      ],
    ];
    String key(Map<String, Object?>? r) => r == null ? '' : '${r['kind']}|${r['rrule']}|${jsonEncode(r['calendar'])}|${r['workdays_region']}';
    final selected = key(current == null
        ? null
        : {'kind': current['kind'], 'rrule': current['rrule'], 'calendar': current['calendar'], 'workdays_region': current['workdays_region']});
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, o) in options.indexed)
                ListTile(
                  key: Key('repeat-$i'),
                  leading: Icon(key(o) == selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  title: Text(o == null ? l.recurNone : describeRecurrence(context, o)),
                  onTap: () async {
                    Navigator.pop(context);
                    await onPick(o);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
