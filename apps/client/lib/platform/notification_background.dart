import 'dart:ui' show DartPluginRegistrant, PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

import '../data/providers.dart' show OfflineSyncApi, loadBundledHolidays, openAppDatabase;
import '../data/reminders.dart';
import '../l10n/app_localizations.dart';
import 'device_time.dart';
import 'local_notifications.dart';

/// Nút Xong/Hoãn bấm khi app đang tắt: plugin chạy hàm này ở isolate nền (reminder-engine.md §3).
/// Ghi DB local + outbox rồi lập lịch lại (hoãn cần thông báo mới ngay). Đồng bộ lên server lần mở app sau.
@pragma('vm:entry-point')
void onNotificationActionInBackground(NotificationResponse response) {
  _handle(response.actionId, response.payload);
}

Future<void> _handle(String? actionId, String? payload) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final db = openAppDatabase();
  try {
    final deviceId = await InstallInfo.deviceId(db);
    final engine = SyncEngine(db: db, api: const OfflineSyncApi(), clock: HlcClock(deviceId), deviceId: deviceId);
    final changed = await NotificationActionHandler(ItemsRepository(engine)).handle(actionId, payload);
    if (!changed) return;
    await loadBundledHolidays(deviceRegion());
    final locale = await savedUiLocale(db) ?? PlatformDispatcher.instance.locale;
    final os = LocalNotificationScheduler();
    await os.init(AppNotificationTexts(lookupAppLocalizations(locale), localeTag: locale.toLanguageTag(), use24h: false).labels);
    await rescheduleReminders(
      db: db,
      os: os,
      deviceTz: await deviceTimeZone(),
      locale: locale,
      use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
    );
  } finally {
    await db.close();
  }
}
