import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

/// Tôi → Ngôn ngữ & vùng (UX §1): quốc gia ngày lễ (lịch, gợi ý dời việc, "ngày làm việc") và hệ lịch phụ (ngày âm trên lịch, lặp âm lịch).
/// Lưu trên máy ([LocalPrefs]); ngôn ngữ giao diện, định dạng, giọng nói theo máy (chưa có lựa chọn).
class LanguageRegionScreen extends ConsumerWidget {
  const LanguageRegionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final region = ref.watch(holidayRegionSettingProvider).value ?? prefAuto;
    final calendar = ref.watch(calendarSystemSettingProvider).value ?? prefAuto;
    final packs = ref.watch(bundledHolidayCalendarsProvider).value ?? const <HolidayCalendar>[];
    final device = ref.watch(deviceRegionProvider)?.toUpperCase();
    final devicePack = packs.where((p) => p.region == device).firstOrNull;
    final autoLunar = effectiveLunarSystem(prefAuto, lang);

    Future<void> set(String pref, String value) async {
      await ref.read(localPrefsProvider).set(pref, value);
      ref
        ..invalidate(holidayRegionSettingProvider)
        ..invalidate(calendarSystemSettingProvider);
    }

    Widget option(String key, String pref, String value, String current, String title) => ListTile(
          key: Key(key),
          leading: Icon(current == value ? Icons.radio_button_checked : Icons.radio_button_unchecked),
          title: Text(title),
          selected: current == value,
          onTap: () => set(pref, value),
        );

    String lunarName(LunarSystem s) => switch (s) {
          LunarSystem.vi => l.lunarVi,
          LunarSystem.zh => l.lunarZh,
          LunarSystem.ko => l.lunarKo,
        };

    return Scaffold(
      appBar: AppBar(title: Text(l.meLanguageRegion)),
      body: ListView(
        children: [
          _header(context, l.settingsHolidayCountry, l.settingsHolidayCountryHint),
          option('holidayRegion-auto', holidayRegionPref, prefAuto, region,
              devicePack == null ? l.settingsSameAsDevice : l.settingsSameAsDeviceNamed(devicePack.name(lang))),
          for (final p in packs) option('holidayRegion-${p.region}', holidayRegionPref, p.region, region, p.name(lang)),
          option('holidayRegion-none', holidayRegionPref, prefNone, region, l.settingsNone),
          _header(context, l.settingsCalendarSystem, l.settingsCalendarSystemHint),
          option('calendarSystem-auto', calendarSystemPref, prefAuto, calendar,
              autoLunar == null ? l.settingsSameAsLanguageNone : l.settingsSameAsLanguage(lunarName(autoLunar))),
          for (final s in LunarSystem.values) option('calendarSystem-${s.wire}', calendarSystemPref, s.wire, calendar, lunarName(s)),
          option('calendarSystem-none', calendarSystemPref, prefNone, calendar, l.settingsNone),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String title, String hint) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space4, Tokens.screenMargin, Tokens.space1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
            Text(hint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}
