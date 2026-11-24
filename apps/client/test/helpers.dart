import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/app.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_platform/remindme_platform.dart';
import 'package:remindme_platform/testing.dart';

/// Giờ cố định cho test: 1/12/2026 10:00 giờ máy chạy test.
final testNow = DateTime(2026, 12, 1, 10);

/// OS giả của lần pumpApp gần nhất (thông báo đã lập lịch, quyền).
late InMemoryNotificationScheduler testOs;

/// App với DB in-memory. Trả container để test đọc repo/DB.
Future<ProviderContainer> pumpApp(WidgetTester tester,
    {required Size size, Locale? locale, double textScale = 1.0, String? region = 'US', Future<void> Function(ItemsRepository repo)? seed,
    NotificationHealth health = const NotificationHealth(notificationsAllowed: true), Stream<NotificationTap>? taps,
    List<Override> overrides = const []}) async {
  testOs = InMemoryNotificationScheduler(maxPending: 60, healthValue: health);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    deviceIdProvider.overrideWithValue('test-device'),
    deviceTimeZoneProvider.overrideWithValue('Asia/Ho_Chi_Minh'),
    deviceRegionProvider.overrideWithValue(region),
    notificationSchedulerProvider.overrideWithValue(testOs),
    notificationTapsProvider.overrideWithValue(taps ?? const Stream.empty()),
    nowProvider.overrideWithValue(() => testNow),
    ...overrides,
  ]);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    // Lập lịch nhắc có thể còn dở (transaction trong zone fake-async): cho chạy xong, nếu không db.close() chờ mãi.
    await tester.pump(const Duration(seconds: 1));
    container.dispose();
    // Câu lệnh bắt đầu trong zone fake-async có thể không bao giờ xong sau khi test dừng đồng hồ giả;
    // DB in-memory bỏ đi nên đóng có giới hạn thời gian (app thật không có zone giả).
    await tester.runAsync(() => db.close().timeout(const Duration(seconds: 2), onTimeout: () {}));
  });
  if (seed != null) await tester.runAsync(() => seed(container.read(itemsRepositoryProvider)));
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: RemindMeApp(locale: locale)));
  await tester.pumpAndSettle();
  return container;
}

/// Chờ ReminderBinding lập lịch (debounce 300 ms). Gọi trước mọi `tester.runAsync` đọc DB để tránh kẹt khóa transaction.
Future<void> settleReminders(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}
