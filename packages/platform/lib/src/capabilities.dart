import 'package:remindme_core/remindme_core.dart';

/// Năng lực của nền tảng đang chạy. UI ẩn/hiện tính năng theo đây, không dùng `Platform.isX`
/// (architecture/multi-platform.md §2 quy tắc 3). Mặc định theo ma trận §3; bản adapter có thể ghi đè sau khi dò thực tế
/// (ví dụ OCR Windows phụ thuộc language pack đã cài).
class PlatformCapabilities {
  const PlatformCapabilities({
    required this.platform,
    required this.canPurchaseInApp,
    required this.hasExactAlarms,
    required this.canScheduleLocalNotifications,
    required this.hasPush,
    required this.hasOcr,
    required this.hasOnDeviceStt,
    required this.hasShareExtension,
    required this.hasWidgets,
    required this.hasWatch,
    required this.canWriteDeviceCalendar,
    required this.receivesRemindersByDefault,
  });

  factory PlatformCapabilities.defaultsFor(DevicePlatform p) => switch (p) {
        DevicePlatform.android => const PlatformCapabilities(
            platform: DevicePlatform.android, canPurchaseInApp: true, hasExactAlarms: true,
            canScheduleLocalNotifications: true, hasPush: true, hasOcr: true, hasOnDeviceStt: true,
            hasShareExtension: true, hasWidgets: true, hasWatch: true, canWriteDeviceCalendar: true,
            receivesRemindersByDefault: true),
        DevicePlatform.ios || DevicePlatform.ipados => PlatformCapabilities(
            platform: p, canPurchaseInApp: true, hasExactAlarms: false,
            canScheduleLocalNotifications: true, hasPush: true, hasOcr: true, hasOnDeviceStt: true,
            hasShareExtension: true, hasWidgets: true, hasWatch: p == DevicePlatform.ios, canWriteDeviceCalendar: true,
            receivesRemindersByDefault: true),
        DevicePlatform.macos => const PlatformCapabilities(
            platform: DevicePlatform.macos, canPurchaseInApp: true, hasExactAlarms: false,
            canScheduleLocalNotifications: true, hasPush: true, hasOcr: true, hasOnDeviceStt: true,
            hasShareExtension: false, hasWidgets: false, hasWatch: false, canWriteDeviceCalendar: true,
            receivesRemindersByDefault: false),
        DevicePlatform.windows => const PlatformCapabilities(
            platform: DevicePlatform.windows, canPurchaseInApp: false, hasExactAlarms: false,
            canScheduleLocalNotifications: true, hasPush: false, hasOcr: true, hasOnDeviceStt: false,
            hasShareExtension: false, hasWidgets: false, hasWatch: false, canWriteDeviceCalendar: false,
            receivesRemindersByDefault: false),
        DevicePlatform.web || DevicePlatform.linux => PlatformCapabilities(
            platform: p, canPurchaseInApp: p == DevicePlatform.web, hasExactAlarms: false,
            canScheduleLocalNotifications: false, hasPush: p == DevicePlatform.web, hasOcr: false, hasOnDeviceStt: false,
            hasShareExtension: false, hasWidgets: false, hasWatch: false, canWriteDeviceCalendar: false,
            receivesRemindersByDefault: false),
      };

  final DevicePlatform platform;
  /// Windows: không có SDK RevenueCat, chỉ hiện trạng thái gói (ADR-014). Web: RevenueCat Web Billing.
  final bool canPurchaseInApp;
  /// Android `setAlarmClock`/exact alarm. iOS không có (dùng UNNotification + rolling window).
  final bool hasExactAlarms;
  final bool canScheduleLocalNotifications;
  final bool hasPush;
  final bool hasOcr;
  final bool hasOnDeviceStt;
  final bool hasShareExtension;
  final bool hasWidgets;
  final bool hasWatch;
  final bool canWriteDeviceCalendar;
  /// Máy tính mặc định không kêu nhắc để tránh kêu 3 nơi (reminder-engine.md §8).
  final bool receivesRemindersByDefault;

  DeviceClass get defaultDeviceClass => resolveDeviceClass(platform, null);
}
