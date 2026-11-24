import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/app.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_data/remindme_data.dart';

/// Giờ cố định cho test: 1/12/2026 10:00 giờ máy chạy test.
final testNow = DateTime(2026, 12, 1, 10);

/// App với DB in-memory. Trả container để test đọc repo/DB.
Future<ProviderContainer> pumpApp(WidgetTester tester,
    {required Size size, Locale? locale, double textScale = 1.0, Future<void> Function(ItemsRepository repo)? seed}) async {
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
    nowProvider.overrideWithValue(() => testNow),
  ]);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await db.close();
  });
  if (seed != null) await tester.runAsync(() => seed(container.read(itemsRepositoryProvider)));
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: RemindMeApp(locale: locale)));
  await tester.pumpAndSettle();
  return container;
}
