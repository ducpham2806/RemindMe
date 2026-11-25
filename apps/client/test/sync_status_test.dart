import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_client/data/remote/remote_sync.dart';

import 'helpers.dart';

const phone = Size(390, 844);

void main() {
  testWidgets('không có server: không banner, không thẻ Đồng bộ', (tester) async {
    await pumpApp(tester, size: phone);
    expect(find.byKey(const Key('offlineBanner')), findsNothing);
    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meSync')), findsNothing);
  });

  testWidgets('offline: banner trên Hôm nay; Tôi hiện trạng thái + số thay đổi chờ đồng bộ', (tester) async {
    await pumpApp(tester, size: phone, seed: (r) => r.create(title: 'Buy milk'), overrides: [
      remoteSyncStatusProvider.overrideWith((ref) => Stream.value((state: RemoteSyncState.offline, lastOk: null))),
    ]);
    expect(find.text("You're offline. Reminders still ring on time, and your changes sync when you're back online."), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('meSync')), matching: find.text("Offline. Changes sync when you're back online.")),
        findsOneWidget);
    expect(find.text('1 change waiting to sync'), findsOneWidget, reason: 'việc vừa tạo còn trong outbox');
  });

  testWidgets('đã đồng bộ: "Synced at <giờ>", không banner', (tester) async {
    await pumpApp(tester, size: phone, overrides: [
      remoteSyncStatusProvider.overrideWith((ref) => Stream.value((state: RemoteSyncState.ok, lastOk: DateTime.utc(2026, 12, 1, 8, 5)))),
    ]);
    expect(find.byKey(const Key('offlineBanner')), findsNothing);
    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pumpAndSettle();
    final local = DateTime.utc(2026, 12, 1, 8, 5).toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    expect(find.text('Synced at $hour:05 ${local.hour < 12 ? 'AM' : 'PM'}'), findsOneWidget, reason: 'giờ theo máy');
  });
}
