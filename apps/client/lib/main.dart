import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_platform/remindme_platform.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'app.dart';
import 'core/l10n/locale_resolution.dart';
import 'data/providers.dart';
import 'data/remote/account.dart';
import 'data/remote/remote_sync.dart';
import 'data/remote/supabase_config.dart';
import 'data/remote/supabase_sync_api.dart';
import 'data/reminders.dart';
import 'l10n/app_localizations.dart';
import 'platform/device_info.dart';
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
  // Server (S1): có cấu hình thì đăng nhập + đồng bộ; không có thì app chạy offline như trước.
  final remote = await _initRemote(db, deviceId, tz, appearance);
  runApp(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      deviceIdProvider.overrideWithValue(deviceId),
      deviceTimeZoneProvider.overrideWithValue(tz),
      notificationSchedulerProvider.overrideWithValue(os),
      notificationTapsProvider.overrideWithValue(local?.taps ?? const Stream.empty()),
      launchNotificationTapProvider.overrideWithValue(launchTap),
      initialAppearanceProvider.overrideWithValue(appearance),
      if (remote != null) ...[
        syncApiProvider.overrideWithValue(remote.api),
        remoteSyncProvider.overrideWith((ref) => remote.sync(ref.watch(syncEngineProvider))),
        accountProvider.overrideWith((ref) => remote.account(ref.watch(syncEngineProvider), ref.watch(remoteSyncProvider)!)),
      ],
    ],
    child: const RemindMeApp(),
  ));
}

/// Khởi tạo Supabase (phiên đăng nhập lưu trên máy, tự refresh token). Trả null khi build không có cấu hình.
Future<({SupabaseSyncApi api, RemoteSync Function(SyncEngine) sync, AccountApi Function(SyncEngine, RemoteSync) account})?> _initRemote(
    AppDatabase db, String deviceId, String tz, Appearance appearance) async {
  if (!SupabaseConfig.isConfigured) return null;
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  final client = Supabase.instance.client;
  Future<DeviceProfile> profile() async {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = dispatcher.views.firstOrNull;
    final shortest = view == null ? 0.0 : (view.physicalSize / view.devicePixelRatio).shortestSide;
    final prefs = LocalPrefs(db);
    // Đọc lại mỗi lượt: người dùng đổi ngôn ngữ, quốc gia ngày lễ, hệ lịch trong app thì profile trên server đổi theo.
    final language = await prefs.get(appLanguagePref) ?? appearance.language;
    final locale = language == prefAuto ? dispatcher.locale : Locale(language, dispatcher.locale.countryCode);
    final region = effectiveHolidayRegion(await prefs.get(holidayRegionPref) ?? prefAuto, deviceRegion()) ??
        deviceRegion()?.toUpperCase();
    final lunar = effectiveLunarSystem(await prefs.get(calendarSystemPref) ?? prefAuto, locale.languageCode);
    return (
      uiLocale: locale.toLanguageTag(),
      region: region,
      homeTz: tz,
      platform: sessionPlatform(),
      deviceClass: shortest >= 600 ? 'tablet' : 'phone',
      appVersion: null,
      calendarSystems: [?lunar?.wire],
    );
  }

  return (
    api: SupabaseSyncApi(client),
    sync: (SyncEngine engine) => RemoteSync(client: client, engine: engine, deviceId: deviceId, profile: profile),
    account: (SyncEngine engine, RemoteSync sync) =>
        SupabaseAccount(client: client, engine: engine, sync: sync, deviceId: deviceId, deviceProfile: profile),
  );
}
