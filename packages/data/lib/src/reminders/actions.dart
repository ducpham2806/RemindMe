import 'dart:convert';

import '../items_repository.dart';

/// ID nút trên thông báo (trùng tên thuộc tính `notification_action.action` trong analytics-events.md).
abstract final class NotificationActionIds {
  static const done = 'done';
  static const snooze10 = 'snooze_10';
  static const snooze60 = 'snooze_60';
}

/// Payload gắn vào thông báo ([PlannedNotification.payload]): item, reminder, lần (không có nội dung item).
class NotificationPayload {
  const NotificationPayload(this.itemId, this.reminderId, this.occurrenceAt);

  static NotificationPayload? tryParse(String? s) {
    if (s == null) return null;
    try {
      final m = jsonDecode(s) as Map<String, Object?>;
      return NotificationPayload(m['i']! as String, m['r']! as String,
          DateTime.fromMillisecondsSinceEpoch(m['o']! as int, isUtc: true));
    } on Object {
      return null;
    }
  }

  final String itemId;
  final String reminderId;
  final DateTime occurrenceAt;
}

/// Xử lý nút Xong/Hoãn (reminder-engine.md §3, §8): ghi DB local + outbox; người gọi lập lịch lại sau đó.
/// Chạy được cả ở isolate nền (app đang đóng) lẫn khi app đang mở.
class NotificationActionHandler {
  NotificationActionHandler(this.repo, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final ItemsRepository repo;
  final DateTime Function() _now;

  /// Trả true nếu đã đổi dữ liệu (cần lập lịch lại).
  Future<bool> handle(String? actionId, String? payload) async {
    final p = NotificationPayload.tryParse(payload);
    if (p == null) return false;
    switch (actionId) {
      case NotificationActionIds.done:
        if (await repo.isRecurring(p.itemId)) {
          await repo.completeOccurrence(p.itemId, p.occurrenceAt);
        } else {
          await repo.setDone(p.itemId, done: true);
        }
        return true;
      case NotificationActionIds.snooze10 || NotificationActionIds.snooze60:
        final minutes = actionId == NotificationActionIds.snooze10 ? 10 : 60;
        await repo.snooze(p.reminderId, until: _now().toUtc().add(Duration(minutes: minutes)));
        return true;
      default:
        return false; // bấm vào thông báo: app mở chi tiết item
    }
  }
}
