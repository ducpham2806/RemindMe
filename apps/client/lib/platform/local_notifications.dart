import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart' show NotificationActionIds;
import 'package:remindme_platform/remindme_platform.dart';
import 'package:timezone/timezone.dart' as tz;

/// Chuỗi đã dịch cho nút và kênh thông báo (từ ARB, đăng ký lúc khởi tạo).
class NotificationLabels {
  const NotificationLabels({
    required this.done,
    required this.snooze10,
    required this.snooze60,
    required this.channelReminders,
    required this.channelAlarms,
    required this.channelQuiet,
  });
  final String done;
  final String snooze10;
  final String snooze60;
  final String channelReminders;
  final String channelAlarms;
  final String channelQuiet;
}

const _category = 'reminder';
const _channelDefault = 'reminders_default';
const _channelAlarm = 'reminders_alarm';
/// Giờ yên lặng: kênh riêng không âm thanh/rung (Android không đổi được âm thanh của 1 kênh sau khi tạo).
const _channelQuiet = 'reminders_quiet';

/// Adapter `NotificationScheduler` trên `flutter_local_notifications` (reminder-engine.md §2, §3).
/// Android: exact alarm nếu được cấp (`setAlarmClock` cho nhắc kiểu báo thức), không thì inexact; iOS: category có Xong/Hoãn.
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<NotificationTap>.broadcast();
  NotificationLabels? _labels;

  /// Bấm thông báo hoặc nút khi app đang chạy.
  Stream<NotificationTap> get taps => _taps.stream;

  static bool get supported =>
      !kIsWeb && const {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS}.contains(defaultTargetPlatform);

  static bool get _apple => defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Khởi tạo plugin; trả lần bấm đã mở app (app đang tắt) nếu có.
  /// [onBackground] phải là hàm top-level có `@pragma('vm:entry-point')`.
  Future<NotificationTap?> init(NotificationLabels labels, {DidReceiveBackgroundNotificationResponseCallback? onBackground}) async {
    _labels = labels;
    TimeZones.ensureInitialized();
    final darwin = DarwinInitializationSettings(
      // Hỏi quyền sau khi người dùng tạo nhắc đầu tiên, không hỏi lúc mở app (reminder-engine.md §2).
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(_category, actions: [
          DarwinNotificationAction.plain(NotificationActionIds.done, labels.done),
          DarwinNotificationAction.plain(NotificationActionIds.snooze10, labels.snooze10),
          DarwinNotificationAction.plain(NotificationActionIds.snooze60, labels.snooze60),
        ]),
      ],
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
      ),
      onDidReceiveNotificationResponse: (r) => _taps.add(NotificationTap(actionId: r.actionId, payload: r.payload)),
      onDidReceiveBackgroundNotificationResponse: onBackground,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final r = launch?.notificationResponse;
    return launch?.didNotificationLaunchApp == true && r != null ? NotificationTap(actionId: r.actionId, payload: r.payload) : null;
  }

  @override
  int get maxPending => _apple ? 60 : 500;

  @override
  Future<void> schedule(List<ScheduledNotification> notifications) async {
    final l = _labels;
    if (l == null) throw StateError('init() trước khi lập lịch');
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    for (final n in notifications) {
      final quiet = n.silent && !n.isAlarm;
      final android = AndroidNotificationDetails(
        n.isAlarm ? _channelAlarm : (quiet ? _channelQuiet : _channelDefault),
        n.isAlarm ? l.channelAlarms : (quiet ? l.channelQuiet : l.channelReminders),
        importance: n.isAlarm ? Importance.max : (quiet ? Importance.low : Importance.high),
        priority: n.isAlarm ? Priority.max : (quiet ? Priority.low : Priority.high),
        playSound: !quiet,
        enableVibration: !quiet,
        category: n.isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        actions: n.payload == null
            ? null
            : [
                AndroidNotificationAction(NotificationActionIds.done, l.done),
                AndroidNotificationAction(NotificationActionIds.snooze10, l.snooze10),
                AndroidNotificationAction(NotificationActionIds.snooze60, l.snooze60),
              ],
      );
      final darwin = DarwinNotificationDetails(
        categoryIdentifier: n.payload == null ? null : _category,
        interruptionLevel: n.isAlarm ? InterruptionLevel.timeSensitive : (quiet ? InterruptionLevel.passive : InterruptionLevel.active),
        presentSound: !quiet,
      );
      await _plugin.zonedSchedule(
        id: n.notificationId,
        scheduledDate: tz.TZDateTime.from(n.fireAtUtc, tz.UTC),
        notificationDetails: NotificationDetails(android: android, iOS: darwin, macOS: darwin),
        androidScheduleMode: !exact
            ? AndroidScheduleMode.inexactAllowWhileIdle
            : (n.isAlarm ? AndroidScheduleMode.alarmClock : AndroidScheduleMode.exactAllowWhileIdle),
        title: n.title,
        body: n.body,
        payload: n.payload,
      );
    }
  }

  @override
  Future<void> cancel(Iterable<int> notificationIds) async {
    for (final id in notificationIds) {
      await _plugin.cancel(id: id);
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<NotificationHealth> health() async {
    final android = _android;
    if (android != null) {
      return NotificationHealth(
        notificationsAllowed: await android.areNotificationsEnabled() ?? false,
        exactAlarmsAllowed: await android.canScheduleExactNotifications() ?? false,
      );
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final macos = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    final opts = await (ios?.checkPermissions() ?? macos?.checkPermissions());
    return NotificationHealth(notificationsAllowed: opts?.isEnabled ?? false);
  }

  @override
  Future<bool> requestPermission() async {
    final android = _android;
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final macos = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    return await (ios?.requestPermissions(alert: true, sound: true, badge: true) ??
            macos?.requestPermissions(alert: true, sound: true, badge: true)) ??
        false;
  }

  @override
  Future<void> openExactAlarmSettings() async => _android?.requestExactAlarmsPermission();
}

/// Nền tảng chưa có nhắc local trong app (web, Windows/Linux trước Phase 4; multi-platform.md §3).
class NoopNotificationScheduler implements NotificationScheduler {
  const NoopNotificationScheduler();
  @override
  int get maxPending => 0;
  @override
  Future<void> schedule(List<ScheduledNotification> notifications) async {}
  @override
  Future<void> cancel(Iterable<int> notificationIds) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<NotificationHealth> health() async => const NotificationHealth(notificationsAllowed: true);
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> openExactAlarmSettings() async {}
}
