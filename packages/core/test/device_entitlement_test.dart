import 'package:remindme_core/remindme_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveDeviceClass khớp app.device_class_of', () {
    test('web/desktop luôn là computer, ipados luôn là tablet', () {
      expect(resolveDeviceClass(DevicePlatform.web, DeviceClass.phone), DeviceClass.computer);
      expect(resolveDeviceClass(DevicePlatform.windows, null), DeviceClass.computer);
      expect(resolveDeviceClass(DevicePlatform.ipados, DeviceClass.phone), DeviceClass.tablet);
      expect(resolveDeviceClass(DevicePlatform.android, DeviceClass.tablet), DeviceClass.tablet);
      expect(resolveDeviceClass(DevicePlatform.ios, null), DeviceClass.phone);
    });
    test('phân loại theo cạnh ngắn màn hình', () {
      expect(mobileClassFromShortestSide(411), DeviceClass.phone);
      expect(mobileClassFromShortestSide(744), DeviceClass.tablet);
    });
  });

  group('QuotaStatus', () {
    final now = DateTime.utc(2026, 11, 24);
    final q = QuotaStatus.fromJson({
      'plan': 'free',
      'period_end': null,
      'limits': {'max_active_appointments': 10, 'voice_input': -1},
      'usage': {'max_active_appointments': 9},
      'features': {'feature_watch_app': 1},
    }, fetchedAt: now);

    test('wouldExceed theo giới hạn từ server', () {
      expect(q.wouldExceed(EntitlementKey.maxActiveAppointments), isFalse);
      expect(q.wouldExceed(EntitlementKey.maxActiveAppointments, adding: 2), isTrue);
      expect(q.wouldExceed('voice_input', adding: 1000), isFalse);
    });
    test('key không có thì đóng (0)', () {
      expect(q.wouldExceed(EntitlementKey.maxActiveTrips), isTrue);
      expect(q.featureLevel(EntitlementKey.featureEnhancedVoice), 0);
    });
    test('cache hết hạn sau 24h', () {
      expect(q.isStale(now.add(const Duration(hours: 23))), isFalse);
      expect(q.isStale(now.add(const Duration(hours: 25))), isTrue);
    });
  });
}
