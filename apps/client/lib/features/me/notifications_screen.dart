import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart' show QuietHours;

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/setting_row.dart';
import '../../data/providers.dart';
import '../../data/reminders.dart';
import '../../l10n/app_localizations.dart';

/// Tôi → Thông báo & nhắc (Figma C51, reminder-engine.md §2, §5): quyền thông báo (và báo thức chính xác trên Android),
/// mốc nhắc mặc định của việc mới, giờ kêu của việc cả ngày. Lưu trên máy; đổi giờ cả ngày thì lập lịch lại ngay.
/// Giờ yên lặng: nhắc trong khung vẫn hiện nhưng không kêu/rung, nhắc kiểu báo thức vẫn kêu (reminder-engine.md §5b).
/// Chưa có: âm thanh riêng, thiết bị nhận nhắc, hướng dẫn pin theo hãng máy (C34).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _pickOffset(BuildContext context, WidgetRef ref, int? current) async {
    final l = AppLocalizations.of(context);
    final picked = await showAppSheet<(int?,)>(
      context,
      (context) => AppSheet(
        title: l.notifDefaultOffset,
        children: [
          for (final m in <int?>[...reminderPresets, null])
            SheetOption(
              key: Key('defaultReminder-${m ?? 'none'}'),
              icon: m == null ? AppIcons.close : AppIcons.bell,
              title: m == null ? l.quickAddNoReminder : describeReminderOffset(l, m),
              selected: m == current,
              onTap: () => Navigator.of(context).pop((m,)),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(localPrefsProvider).set(defaultReminderPref, picked.$1?.toString() ?? prefNoReminder);
    ref.invalidate(defaultReminderProvider);
  }

  Future<void> _pickAllDayTime(BuildContext context, WidgetRef ref, CivilTime current) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: current.hour, minute: current.minute));
    if (picked == null) return;
    final v = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await ref.read(localPrefsProvider).set(allDayTimePref, v);
    ref.invalidate(allDayTimeProvider);
  }

  Future<void> _setQuiet(WidgetRef ref, {bool? on, QuietHours? window}) async {
    final prefs = ref.read(localPrefsProvider);
    if (on != null) await prefs.set(quietHoursOnPref, on ? '1' : '0');
    if (window != null) await prefs.set(quietHoursPref, window.encode());
    ref.invalidate(quietHoursProvider);
  }

  Future<void> _pickQuietTime(BuildContext context, WidgetRef ref, QuietHours w, {required bool start}) async {
    final t = start ? w.start : w.end;
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: t.hour, minute: t.minute));
    if (picked == null) return;
    final v = CivilTime(picked.hour, picked.minute);
    await _setQuiet(ref, window: start ? QuietHours(v, w.end) : QuietHours(w.start, v));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final fmt = Fmt.of(context);
    final health = ref.watch(notificationHealthProvider).value;
    final offset = ref.watch(defaultReminderProvider);
    final allDay = ref.watch(allDayTimeProvider).value ?? defaultAllDayTime;
    final quiet = ref.watch(quietHoursProvider).value ?? (on: false, window: suggestedQuietHours);
    final qStart = fmt.clock(quiet.window.start), qEnd = fmt.clock(quiet.window.end);
    final os = ref.read(notificationSchedulerProvider);
    final small = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant);
    final allowed = health?.notificationsAllowed ?? true;
    final exact = health?.exactAlarmsAllowed ?? true;

    Widget section(String title) => Padding(
          padding: const EdgeInsetsDirectional.only(top: Tokens.space5, bottom: 10),
          child: Text(title, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        );
    Widget card(Widget child) => Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.meNotifications)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space3, Tokens.screenMargin, Tokens.space4),
          child: FilledButton.icon(
            key: const Key('notifDone'),
            icon: AppIcon(AppIcons.tick, size: 20, color: scheme.onPrimary),
            label: Text(l.settingsDone),
            onPressed: () => context.canPop() ? context.pop() : context.go('/me'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
        children: [
          Text(l.notifSettingsHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: Tokens.space5),
          Container(
            key: const Key('notifStatus'),
            padding: const EdgeInsetsDirectional.all(Tokens.space4),
            decoration: BoxDecoration(
              color: allowed && exact ? colors.travelContainer : colors.warningContainer,
              borderRadius: BorderRadius.circular(Tokens.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(AppIcons.bell, size: 24, color: allowed && exact ? colors.travel : colors.onWarningContainer),
                    const SizedBox(width: Tokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(allowed ? l.notifOn : l.notifOff,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600, color: allowed && exact ? colors.travel : colors.onWarningContainer)),
                          Text(!allowed ? l.notifOffBody : (exact ? l.notifOnBody : l.notifExactOff), style: small),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!allowed || !exact) ...[
                  const SizedBox(height: Tokens.space3),
                  FilledButton.tonal(
                    key: const Key('notifAllow'),
                    onPressed: () async {
                      if (!allowed) {
                        await os.requestPermission();
                      } else {
                        await os.openExactAlarmSettings();
                      }
                      ref.invalidate(notificationHealthProvider);
                    },
                    child: Text(!allowed ? l.notifAllow : l.notifExactAllow),
                  ),
                ],
              ],
            ),
          ),
          section(l.notifDefaults),
          card(SettingRow(
            key: const Key('notifDefaultOffset'),
            icon: AppIcons.clock,
            label: l.notifDefaultOffset,
            value: switch (offset) {
              AsyncData(:final value) => value == null ? l.quickAddNoReminder : describeReminderOffset(l, value),
              _ => '',
            },
            onTap: () => _pickOffset(context, ref, offset.value),
          )),
          const SizedBox(height: 10),
          card(SettingRow(
            key: const Key('notifAllDayTime'),
            icon: AppIcons.calendar,
            label: l.notifAllDayTime,
            value: fmt.clock(allDay),
            onTap: () => _pickAllDayTime(context, ref, allDay),
          )),
          section(l.notifQuietSection),
          card(Column(
            children: [
              SwitchListTile(
                key: const Key('notifQuiet'),
                value: quiet.on,
                onChanged: (v) => _setQuiet(ref, on: v),
                title: Text(l.notifQuietToggle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                subtitle: Text(quiet.on ? l.notifQuietOn(qStart, qEnd) : l.notifQuietOff(qStart, qEnd), key: const Key('notifQuietSummary'), style: small),
              ),
              if (quiet.on) ...[
                SettingRow(
                  key: const Key('notifQuietStart'),
                  icon: AppIcons.moon,
                  label: l.notifQuietStart,
                  value: qStart,
                  onTap: () => _pickQuietTime(context, ref, quiet.window, start: true),
                ),
                SettingRow(
                  key: const Key('notifQuietEnd'),
                  icon: AppIcons.clock,
                  label: l.notifQuietEnd,
                  value: qEnd,
                  onTap: () => _pickQuietTime(context, ref, quiet.window, start: false),
                ),
              ],
            ],
          )),
          const SizedBox(height: Tokens.space2),
          Text(l.notifQuietAlarmNote, style: small),
          const SizedBox(height: Tokens.space5),
          Text(l.notifSystemNote, style: small),
        ],
      ),
    );
  }
}
