import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/choice_buttons.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

/// Tôi → Ngôn ngữ & vùng (UX §1, Figma C50): ngôn ngữ giao diện, định dạng + múi giờ (theo máy, chỉ xem), quốc gia ngày lễ
/// (lịch, gợi ý dời việc, "ngày làm việc") và hệ lịch phụ (ngày âm trên lịch, lặp âm lịch). Lưu trên máy ([LocalPrefs]).
/// Chưa có chọn giọng nói (Figma có hàng này): chờ nhập bằng giọng nói.
class LanguageRegionScreen extends ConsumerWidget {
  const LanguageRegionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = Fmt.of(context);
    final now = ref.watch(nowProvider)();
    final tz = ref.watch(deviceTimeZoneProvider);
    final appearance = ref.watch(appearanceProvider);
    final options = _Options.of(context, ref);
    final deviceFormat = View.of(context).platformDispatcher.locale.toLanguageTag();
    final weekend = (weekendDays(options.effectiveRegion).toList()..sort()).map(fmt.weekdayName).join(', ');
    final secondary = theme.textTheme.bodySmall;
    const gap = SizedBox(height: 18);

    Widget section(String title) => Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 10),
          child: Text(title, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.meLanguageRegion)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space3, Tokens.screenMargin, Tokens.space4),
          child: FilledButton.icon(
            key: const Key('langRegionDone'),
            icon: AppIcon(AppIcons.tick, size: 20, color: scheme.onPrimary),
            label: Text(l.langRegionDone),
            onPressed: () => context.canPop() ? context.pop() : context.go('/me'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
        children: [
          Text(l.langRegionHint, style: secondary),
          const SizedBox(height: Tokens.space5),
          Container(
            padding: const EdgeInsetsDirectional.all(14),
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
            child: Row(
              children: [
                AppIcon(AppIcons.globe, size: 26, color: scheme.primary),
                const SizedBox(width: Tokens.space3),
                Expanded(child: Text(l.langRegionNote, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13))),
              ],
            ),
          ),
          gap,
          section(l.langRegionAppLanguage),
          ChoiceButtons(
            keyPrefix: 'appLanguage',
            value: appearance.language,
            unselectedColor: scheme.surface,
            options: [(prefAuto, l.meFollowDevice), ('vi', l.langNameVi), ('en', l.langNameEn)],
            onChanged: ref.read(appearanceProvider.notifier).setLanguage,
          ),
          gap,
          section(l.langRegionFormats),
          _SettingRow(icon: AppIcons.globe, label: l.langRegionFormat, value: l.langRegionFromDevice(deviceFormat)),
          const SizedBox(height: 10),
          _SettingRow(icon: AppIcons.calendar, label: l.langRegionTimeZone, value: l.langRegionFromDevice([tz, utcOffsetLabel(now, tz)].join(' · '))),
          gap,
          section(l.langRegionHolidays),
          _SettingRow(
            key: const Key('langRegionHolidays'),
            icon: AppIcons.calendar,
            label: l.settingsHolidayCountry,
            value: [options.regionLabel, if (options.effectiveRegion != null) l.settingsWeekend(weekend)].join(' · '),
            onTap: () => _pick(context, ref, l.settingsHolidayCountry, l.settingsHolidayCountryHint, holidayRegionPref, options.region, options.regions),
          ),
          const SizedBox(height: 10),
          _SettingRow(
            key: const Key('langRegionCalendar'),
            label: l.settingsCalendarSystem,
            value: options.calendarLabel,
            onTap: () =>
                _pick(context, ref, l.settingsCalendarSystem, l.settingsCalendarSystemHint, calendarSystemPref, options.calendar, options.calendars),
          ),
          gap,
          Text(l.langRegionPreview([fmt.numericDate(now), fmt.time(now)].join(' · ')), style: secondary),
          Text(l.langRegionPreviewHint, style: secondary),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, String title, String hint, String pref, String current,
      List<(String, String)> choices) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.screenMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(hint, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              for (final (value, label) in choices)
                ListTile(
                  key: Key('${pref == holidayRegionPref ? 'holidayRegion' : 'calendarSystem'}-$value'),
                  leading: Icon(value == current ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  title: Text(label),
                  selected: value == current,
                  onTap: () => Navigator.of(context).pop(value),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == current) return;
    await ref.read(localPrefsProvider).set(pref, picked);
    ref
      ..invalidate(holidayRegionSettingProvider)
      ..invalidate(calendarSystemSettingProvider);
  }
}

/// Lựa chọn và nhãn của 2 cài đặt ngày lễ / hệ lịch.
class _Options {
  const _Options({
    required this.region,
    required this.calendar,
    required this.regions,
    required this.calendars,
    required this.effectiveRegion,
  });

  factory _Options.of(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final region = ref.watch(holidayRegionSettingProvider).value ?? prefAuto;
    final calendar = ref.watch(calendarSystemSettingProvider).value ?? prefAuto;
    final packs = ref.watch(bundledHolidayCalendarsProvider).value ?? const <HolidayCalendar>[];
    final device = ref.watch(deviceRegionProvider)?.toUpperCase();
    final devicePack = packs.where((p) => p.region == device).firstOrNull;
    final autoLunar = effectiveLunarSystem(prefAuto, lang);
    String lunarName(LunarSystem s) => switch (s) {
          LunarSystem.vi => l.lunarVi,
          LunarSystem.zh => l.lunarZh,
          LunarSystem.ko => l.lunarKo,
        };
    return _Options(
      region: region,
      calendar: calendar,
      effectiveRegion: effectiveHolidayRegion(region, device),
      regions: [
        (prefAuto, devicePack == null ? l.settingsSameAsDevice : l.settingsSameAsDeviceNamed(devicePack.name(lang))),
        for (final p in packs) (p.region, p.name(lang)),
        (prefNone, l.settingsNone),
      ],
      calendars: [
        (prefAuto, autoLunar == null ? l.settingsSameAsLanguageNone : l.settingsSameAsLanguage(lunarName(autoLunar))),
        for (final s in LunarSystem.values) (s.wire, lunarName(s)),
        (prefNone, l.settingsNone),
      ],
    );
  }

  final String region, calendar;
  final String? effectiveRegion;
  final List<(String, String)> regions, calendars;

  String get regionLabel => regions.where((r) => r.$1 == region).firstOrNull?.$2 ?? region;
  String get calendarLabel => calendars.where((c) => c.$1 == calendar).firstOrNull?.$2 ?? calendar;
}

/// Hàng cài đặt dạng thẻ: nhãn nhỏ + giá trị; chạm được thì có mũi tên.
class _SettingRow extends StatelessWidget {
  const _SettingRow({super.key, this.icon, required this.label, required this.value, this.onTap});
  final AppIcons? icon;
  final String label, value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(14),
          child: Row(
            children: [
              if (icon != null) ...[AppIcon(icon!, size: 21, color: scheme.primary), const SizedBox(width: Tokens.space3)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodySmall),
                    const SizedBox(height: Tokens.space1),
                    Text(value, style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
              if (onTap != null) AppIcon(AppIcons.chevronSmall, size: 17, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
