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
import '../schedule/date_time_sheet.dart';
import '../schedule/repeat_sheet.dart';

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

    final region = ref.watch(holidayRegionProvider).value ?? ref.watch(deviceRegionProvider);

    // Ngày và giờ chọn cùng 1 sheet (Figma 05); việc chưa có ngày thì mặc định hôm nay, cả ngày.
    Future<void> pickDateTime() async {
      final picked = await showDateTimeSheet(context,
          today: today, tz: tz, now: ref.read(nowProvider)(), region: region, date: wall?.date, time: wall?.time);
      if (picked != null) await save(date: picked.date, time: picked.time);
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
                onTap: pickDateTime,
              ),
              if (wall != null)
                SettingValueButton(
                  key: const Key('pickTime'),
                  label: wall.time == null
                      ? l.itemAddTime
                      : MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: wall.time!.hour, minute: wall.time!.minute),
                          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context)),
                  onTap: pickDateTime,
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
              : () async {
                  final picked = await showRepeatSheet(context,
                      title: item.title,
                      date: wall.date,
                      time: wall.time,
                      current: rule,
                      region: region,
                      lunarSystem: effectiveLunarSystem(
                          ref.read(calendarSystemSettingProvider).value ?? prefAuto, Localizations.localeOf(context).languageCode),
                      today: today,
                      tz: tz,
                      now: ref.read(nowProvider)());
                  if (picked == null) return;
                  // Lặp âm lịch dời item về lần tới (giữ giờ đã chọn trong sheet).
                  final at = picked.start ?? wall;
                  if (picked.start != null) {
                    if (at.time == null) {
                      await repo.setSchedule(item.id, startDate: at.date.toIso(), tz: tz);
                    } else {
                      await repo.setSchedule(item.id, startsAt: TimeZones.toUtc(at, tz).utc, tz: tz);
                    }
                  }
                  final start = TimeZones.toUtc(at.time == null ? CivilDateTime(at.date, CivilTime(0)) : at, tz).utc;
                  await repo.setRecurrence(item.id, picked.rule, start: start);
                },
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
}
