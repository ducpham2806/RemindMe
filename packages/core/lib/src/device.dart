/// Nền tảng và loại thiết bị, khớp `user_sessions.platform` / `device_class` và hàm SQL `app.device_class_of` (ADR-013).
enum DevicePlatform { ios, ipados, android, web, macos, windows, linux }

enum DeviceClass { phone, tablet, computer }

/// Web/desktop luôn là computer, iPadOS luôn là tablet; iOS/Android lấy theo kích thước màn hình app báo.
DeviceClass resolveDeviceClass(DevicePlatform platform, DeviceClass? reported) => switch (platform) {
      DevicePlatform.web || DevicePlatform.macos || DevicePlatform.windows || DevicePlatform.linux => DeviceClass.computer,
      DevicePlatform.ipados => DeviceClass.tablet,
      DevicePlatform.ios || DevicePlatform.android => reported ?? DeviceClass.phone,
    };

/// Ngưỡng tablet theo cạnh ngắn của màn hình (dp), dùng chung với window size class (multi-platform.md §2).
const tabletShortestSideDp = 600.0;

DeviceClass mobileClassFromShortestSide(double shortestSideDp) =>
    shortestSideDp >= tabletShortestSideDp ? DeviceClass.tablet : DeviceClass.phone;
