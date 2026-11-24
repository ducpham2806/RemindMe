/// Bản giả cho test (không gọi OS). Dùng trong test của packages/data và apps/client.
library;

import 'remindme_platform.dart';

class InMemoryNotificationScheduler implements NotificationScheduler {
  InMemoryNotificationScheduler({this.maxPending = 500, this.healthValue = const NotificationHealth(notificationsAllowed: true)});

  @override
  final int maxPending;
  NotificationHealth healthValue;
  final pending = <int, ScheduledNotification>{};
  int scheduledCalls = 0, cancelledCalls = 0, permissionRequests = 0;

  @override
  Future<void> schedule(List<ScheduledNotification> notifications) async {
    scheduledCalls += notifications.length;
    for (final n in notifications) {
      pending[n.notificationId] = n;
    }
  }

  @override
  Future<void> cancel(Iterable<int> notificationIds) async {
    cancelledCalls += notificationIds.length;
    notificationIds.forEach(pending.remove);
  }

  @override
  Future<void> cancelAll() async => pending.clear();

  @override
  Future<NotificationHealth> health() async => healthValue;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    healthValue = NotificationHealth(notificationsAllowed: true, exactAlarmsAllowed: healthValue.exactAlarmsAllowed);
    return true;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    healthValue = NotificationHealth(notificationsAllowed: healthValue.notificationsAllowed);
  }
}
