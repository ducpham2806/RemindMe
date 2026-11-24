/// Interface cho tính năng phụ thuộc nền tảng. Mỗi interface có adapter theo nền tảng (federated plugin hoặc lớp bọc plugin)
/// trong app, inject qua Riverpod. Logic nghiệp vụ chỉ biết interface này.
library;

/// Một lần thông báo đã lập lịch với OS (bảng client `scheduled_notifications`, reminder-engine.md §1).
class ScheduledNotification {
  const ScheduledNotification({
    required this.notificationId,
    required this.reminderId,
    required this.fireAtUtc,
    required this.title,
    required this.body,
    this.isAlarm = false,
    this.payload,
  });
  final int notificationId;
  final String reminderId;
  final DateTime fireAtUtc;
  final String title;
  final String body;
  final bool isAlarm;
  final String? payload;
}

abstract interface class NotificationScheduler {
  /// Số thông báo tối đa được chờ cùng lúc (iOS 64; Android không giới hạn thực tế).
  int get maxPending;
  Future<void> schedule(List<ScheduledNotification> notifications);
  Future<void> cancel(Iterable<int> notificationIds);
  /// Gọi khi bị đăng xuất (session_revoked) hoặc đổi tài khoản.
  Future<void> cancelAll();
}

/// Kết quả OCR chuẩn hóa (on-device-extraction.md §3): block → line, bbox 0..1.
class OcrLine {
  const OcrLine(this.text, this.left, this.top, this.width, this.height, {this.language});
  final String text;
  final double left, top, width, height;
  final String? language;
}

abstract interface class OcrEngine {
  /// Mã hệ chữ hỗ trợ trên máy này ('latin', 'cjk', 'devanagari', 'arabic'...).
  Future<Set<String>> supportedScripts();
  Future<List<OcrLine>> recognize(String imagePath, {Set<String> scripts});
}

class SttResult {
  const SttResult(this.alternatives, {required this.isFinal, this.locale});
  final List<String> alternatives; // n-best, phần tử đầu tốt nhất
  final bool isFinal;
  final String? locale;
}

abstract interface class SttEngine {
  /// Locale nhận dạng có sẵn, kèm biến thể vùng (en-GB, es-MX...) và có chạy offline không.
  Future<Map<String, bool>> availableLocales();
  Stream<SttResult> listen({required String locale, List<String> biasPhrases, bool onDeviceOnly});
  Future<void> stop();
}

abstract interface class PurchaseService {
  /// Gói đang bán (giá đã bản địa hóa từ store). Rỗng trên nền tảng không bán trong app.
  Future<List<({String productId, String period, String localizedPrice})>> offerings();
  Future<bool> purchase(String productId);
  Future<void> restore();
}

abstract interface class BarcodeScanner {
  /// Chuỗi thô của barcode/QR (BCBP, PDF417...) trong ảnh.
  Future<List<String>> scan(String imagePath);
}

abstract interface class CalendarWriter {
  Future<bool> addEvent({required String title, required DateTime startUtc, DateTime? endUtc, String? tz, String? location});
}

/// File/ảnh/text được chia sẻ vào app (share extension, kéo thả, "Mở bằng").
abstract interface class ShareInbox {
  Stream<({String? path, String? text, String? mime})> incoming();
}

abstract interface class PushChannel {
  Future<String?> token();
  Stream<Map<String, Object?>> dataMessages();
}
