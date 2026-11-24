import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/l10n/formatters.dart';
import '../../core/l10n/recurrence_text.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

const _byday = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// Hệ âm lịch gợi ý theo ngôn ngữ giao diện. Sau này lấy từ `profiles.calendar_systems` (cài đặt người dùng).
LunarSystem? lunarSystemForLanguage(String languageCode) => switch (languageCode) {
      'vi' => LunarSystem.vi,
      'zh' => LunarSystem.zh,
      'ko' => LunarSystem.ko,
      _ => null,
    };

/// Thời điểm (ngày, giờ) và lặp lại của item (UX §2.3). Sửa theo múi giờ của máy.
class ScheduleEditor extends ConsumerWidget {
  const ScheduleEditor({super.key, required this.item});
  final ItemView item;

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
    return Column(
      key: const Key('scheduleEditor'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Tokens.space2,
          runSpacing: Tokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              key: const Key('pickDate'),
              avatar: const Icon(Icons.event, size: 18),
              label: Text(wall == null ? l.itemAddDate : fmt.date(DateTime(wall.date.year, wall.date.month, wall.date.day))),
              onPressed: pickDate,
            ),
            if (wall != null)
              ActionChip(
                key: const Key('pickTime'),
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(wall.time == null
                    ? l.itemAddTime
                    : MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: wall.time!.hour, minute: wall.time!.minute),
                        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))),
                onPressed: pickTime,
              ),
            if (wall?.time != null)
              IconButton(
                key: const Key('removeTime'),
                tooltip: l.itemRemoveTime,
                icon: const Icon(Icons.timer_off_outlined),
                onPressed: () => save(date: wall!.date),
              ),
            if (wall != null)
              IconButton(
                key: const Key('removeDate'),
                tooltip: l.itemRemoveDate,
                icon: const Icon(Icons.event_busy_outlined),
                onPressed: () => save(clear: true),
              ),
          ],
        ),
        ListTile(
          key: const Key('repeatRow'),
          contentPadding: EdgeInsetsDirectional.zero,
          leading: const Icon(Icons.repeat),
          title: Text(l.itemRepeatLabel),
          subtitle: Text(wall == null ? l.recurNeedsDate : (rule == null ? l.recurNone : describeRecurrence(context, rule)),
              style: theme.textTheme.bodySmall),
          enabled: wall != null,
          onTap: wall == null
              ? null
              : () => _pickRepeat(context, current: rule, date: wall.date, onPick: (r) async {
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
      {required Map<String, Object?>? current, required CivilDate date, required Future<void> Function(Map<String, Object?>?) onPick}) {
    final lunarSystem = lunarSystemForLanguage(Localizations.localeOf(context).languageCode);
    final lunar = lunarSystem == null ? null : LunarCalendar(lunarSystem).fromSolar(date);
    final options = <Map<String, Object?>?>[
      null,
      {'kind': 'rrule', 'rrule': 'FREQ=DAILY'},
      {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'},
      {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=${_byday[date.weekday - 1]}'},
      {'kind': 'rrule', 'rrule': 'FREQ=MONTHLY;BYMONTHDAY=${date.day}'},
      {'kind': 'rrule', 'rrule': 'FREQ=YEARLY'},
      if (lunar != null && !lunar.leap) ...[
        {'kind': 'calendar', 'calendar': {'system': lunarSystem!.wire, 'day': lunar.day}},
        {'kind': 'calendar', 'calendar': {'system': lunarSystem.wire, 'month': lunar.month, 'day': lunar.day}},
      ],
    ];
    String key(Map<String, Object?>? r) => r == null ? '' : '${r['kind']}|${r['rrule']}|${jsonEncode(r['calendar'])}';
    final selected = key(current == null ? null : {'kind': current['kind'], 'rrule': current['rrule'], 'calendar': current['calendar']});
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
