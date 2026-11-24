// Thư mục duy nhất trong app được dò nền tảng (multi-platform.md §2 quy tắc 3, kiểm bằng tools/lint-platform-checks.py).
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_platform/remindme_platform.dart';

/// [isLargeScreen]: cạnh ngắn ≥ 600dp; iPad báo là ipados. App iPad chạy trên Mac (isiOSAppOnMac) cần adapter native báo macos (Phase 2).
DevicePlatform detectPlatform({required bool isLargeScreen}) {
  if (kIsWeb) return DevicePlatform.web;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => isLargeScreen ? DevicePlatform.ipados : DevicePlatform.ios,
    TargetPlatform.android => DevicePlatform.android,
    TargetPlatform.macOS => DevicePlatform.macos,
    TargetPlatform.windows => DevicePlatform.windows,
    TargetPlatform.linux || TargetPlatform.fuchsia => DevicePlatform.linux,
  };
}

/// Ghi đè trong test hoặc khi adapter native dò được chính xác hơn.
final devicePlatformProvider = Provider<DevicePlatform>((ref) => detectPlatform(isLargeScreen: false));

final platformCapabilitiesProvider =
    Provider<PlatformCapabilities>((ref) => PlatformCapabilities.defaultsFor(ref.watch(devicePlatformProvider)));
