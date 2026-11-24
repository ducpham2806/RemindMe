import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_platform/remindme_platform.dart';
import 'package:test/test.dart';

void main() {
  test('mọi nền tảng đều có cấu hình mặc định', () {
    for (final p in DevicePlatform.values) {
      expect(PlatformCapabilities.defaultsFor(p).platform, p);
    }
  });

  test('khớp ma trận multi-platform.md §3', () {
    final win = PlatformCapabilities.defaultsFor(DevicePlatform.windows);
    expect(win.canPurchaseInApp, isFalse);
    expect(win.hasPush, isFalse);
    expect(win.defaultDeviceClass, DeviceClass.computer);
    expect(win.receivesRemindersByDefault, isFalse);
    expect(PlatformCapabilities.defaultsFor(DevicePlatform.web).canScheduleLocalNotifications, isFalse);
    expect(PlatformCapabilities.defaultsFor(DevicePlatform.android).hasExactAlarms, isTrue);
    expect(PlatformCapabilities.defaultsFor(DevicePlatform.ipados).defaultDeviceClass, DeviceClass.tablet);
  });
}
