import 'dart:io' show Platform;

/// Tên nền tảng gửi lên `session_claim` (khớp CHECK `user_sessions.platform`). iPad báo 'ios' + device_class 'tablet'.
String sessionPlatform() => Platform.operatingSystem;
