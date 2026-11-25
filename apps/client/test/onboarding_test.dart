import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_platform/remindme_platform.dart';

import 'helpers.dart';

const _size = Size(390, 1000);

void main() {
  testWidgets('onboarding: mục tiêu tạo list, câu mẫu → việc có nhắc, chỉ hỏi quyền khi bấm Cho phép, xong về Hôm nay', (tester) async {
    final c = await pumpApp(tester, size: _size, locale: const Locale('en'), health: const NotificationHealth(notificationsAllowed: false),
        overrides: [initialOnboardingDoneProvider.overrideWithValue(false)]);
    expect(find.text('Welcome'), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcomeContinue')));
    await tester.pumpAndSettle();

    expect(find.text('STEP 2 / 4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('goal-work')));
    await tester.tap(find.byKey(const Key('goal-health')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('goalsContinue')));
    await tester.pumpAndSettle();

    expect(find.text('STEP 3 / 4'), findsOneWidget);
    expect(find.text('Vitamins tomorrow at 8am'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('firstPreview')), matching: find.textContaining('8:00')), findsOneWidget);
    await tester.tap(find.byKey(const Key('firstCreate')));
    await settleReminders(tester);

    expect(find.text('STEP 4 / 4'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('notifyCard')), matching: find.text('Vitamins')), findsOneWidget);
    expect(testOs.permissionRequests, 0, reason: 'đang onboarding: không bật hộp thoại hệ điều hành trước màn giải thích');
    await tester.tap(find.byKey(const Key('notifyAllow')));
    await settleReminders(tester);
    expect(testOs.permissionRequests, 1);
    expect(find.byKey(const Key('nav-0')), findsOneWidget);

    final names = await tester.runAsync(() async => (await c.read(listsRepositoryProvider).watchLists().first).map((s) => s.name).toSet());
    expect(names, containsAll(['Work', 'Health']));
    expect(await tester.runAsync(() => c.read(localPrefsProvider).get(onboardingDonePref)), '1');
    expect(testOs.pending, hasLength(1), reason: 'việc mẫu có nhắc đúng giờ');
  });

  testWidgets('"Dùng thử ngay" bỏ qua hết; "Để sau" không hỏi quyền', (tester) async {
    await pumpApp(tester, size: _size, locale: const Locale('vi'), overrides: [initialOnboardingDoneProvider.overrideWithValue(false)]);
    expect(find.text('Chào mừng'), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcomeTryNow')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav-0')), findsOneWidget);
  });

  testWidgets('tiếng Việt: câu mẫu được hiểu; Bỏ qua bước 3 → Để sau không hỏi quyền', (tester) async {
    await pumpApp(tester, size: _size, locale: const Locale('vi'), health: const NotificationHealth(notificationsAllowed: false),
        overrides: [initialOnboardingDoneProvider.overrideWithValue(false)]);
    await tester.tap(find.byKey(const Key('welcomeContinue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goalsSkip')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('firstPreview')), matching: find.textContaining('08:00')), findsOneWidget);
    await tester.tap(find.byKey(const Key('firstSkip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifyCard')), findsNothing);
    await tester.tap(find.byKey(const Key('notifyLater')));
    await settleReminders(tester);
    expect(testOs.permissionRequests, 0);
    expect(find.byKey(const Key('nav-0')), findsOneWidget);
  });
}
