import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_platform/remindme_platform.dart';

import 'app.dart';
import 'core/l10n/locale_resolution.dart';
import 'data/providers.dart';
import 'data/reminders.dart';
import 'l10n/app_localizations.dart';
import 'platform/device_time.dart';
import 'platform/local_notifications.dart';
import 'platform/notification_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font Be Vietnam Pro (OFL 1.1) đi kèm app: hiện trong màn giấy phép.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const ['Be Vietnam Pro'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final db = openAppDatabase();
  final deviceId = await InstallInfo.deviceId(db);
  final tz = await deviceTimeZone();
  await loadBundledHolidays(effectiveHolidayRegion(await LocalPrefs(db).get(holidayRegionPref) ?? prefAuto, deviceRegion()));
  final appearance = await loadAppearance(LocalPrefs(db));
  // Nút trên thông báo đăng ký theo ngôn ngữ máy lúc khởi động; ReminderBinding đăng ký lại khi ngôn ngữ app khác.
  final locale = appearance.language == prefAuto
      ? resolveLocale(WidgetsBinding.instance.platformDispatcher.locales, appSupportedLocales())
      : Locale(appearance.language);
  final local = LocalNotificationScheduler.supported ? LocalNotificationScheduler() : null;
  final launchTap = await local?.init(
    AppNotificationTexts(lookupAppLocalizations(locale), localeTag: locale.toLanguageTag(), use24h: false).labels,
    onBackground: onNotificationActionInBackground,
  );
  final NotificationScheduler os = local ?? const NoopNotificationScheduler();
  runApp(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      deviceIdProvider.overrideWithValue(deviceId),
      deviceTimeZoneProvider.overrideWithValue(tz),
      notificationSchedulerProvider.overrideWithValue(os),
      notificationTapsProvider.overrideWithValue(local?.taps ?? const Stream.empty()),
      launchNotificationTapProvider.overrideWithValue(launchTap),
      initialAppearanceProvider.overrideWithValue(appearance),
    ],
    child: const RemindMeApp(),
  ));
}
