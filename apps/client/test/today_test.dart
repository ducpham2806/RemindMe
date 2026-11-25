import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/app.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_data/remindme_data.dart';

import 'helpers.dart';

const phone = Size(390, 844);
const en = Locale('en');

Future<void> seedDay(ItemsRepository repo) async {
  final today = DayWindow.ofLocal(testNow);
  await repo.create(title: 'Send quote', startsAt: testNow.subtract(const Duration(days: 1)).toUtc(), tz: 'Etc/UTC');
  await repo.create(title: 'Client meeting', startsAt: DateTime(2026, 12, 1, 14, 30).toUtc(), tz: 'Etc/UTC');
  await repo.create(title: 'Mom’s birthday', startDate: today.localDate);
  await repo.create(title: 'Buy a gift');
}

void main() {
  testWidgets('Hôm nay chia nhóm Quá hạn / Hôm nay / Chưa đặt giờ', (tester) async {
    await pumpApp(tester, size: phone, locale: en, seed: seedDay);
    for (final t in ['Overdue', 'Today', 'No time set', 'Send quote', 'Client meeting', 'Mom’s birthday', 'Buy a gift', 'All day']) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    // Thứ tự nhóm theo UX §2.1.
    final y = [for (final t in ['Send quote', 'Mom’s birthday', 'Client meeting', 'Buy a gift']) tester.getTopLeft(find.text(t)).dy];
    expect(y, orderedEquals([...y]..sort()));
    expect(find.text('2:30 PM'), findsOneWidget);
  });

  testWidgets('Quick Add: Lưu bị khóa khi rỗng, Enter tạo việc vào "Chưa đặt giờ"', (tester) async {
    await pumpApp(tester, size: phone, locale: en);
    expect(find.text('Nothing due today'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quickAddFab')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('quickAddSave'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('quickAddField')), 'Call the bank');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(const Key('quickAddSave'))).onPressed, isNotNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quickAddField')), findsNothing);
    expect(find.text('No time set'), findsOneWidget);
    expect(find.text('Call the bank'), findsOneWidget);
  });

  testWidgets('đánh dấu xong chuyển sang "Đã xong", Hoàn tác đưa về chỗ cũ', (tester) async {
    await pumpApp(tester, size: phone, locale: en, seed: seedDay);
    await tester.tap(find.bySemanticsLabel('Mark as done').last);
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Marked as done'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('vuốt từ đầu dòng = Xong', (tester) async {
    await pumpApp(tester, size: phone, locale: en, seed: seedDay);
    await tester.drag(find.text('Buy a gift'), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('No time set'), findsNothing);
  });

  testWidgets('vuốt về đầu dòng = Hoãn nhắc; việc chưa có nhắc thì thêm nhắc vào giờ hoãn', (tester) async {
    final c = await pumpApp(tester, size: phone, locale: en, seed: seedDay);
    await tester.drag(find.text('Client meeting'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Snooze'), findsOneWidget);
    await tester.tap(find.byKey(const Key('snooze-1h')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('snoozeApply')));
    await settleReminders(tester);
    expect(find.text('Client meeting'), findsOneWidget, reason: 'hoãn không đổi giờ của việc');
    final db = c.read(appDatabaseProvider);
    final r = (await tester.runAsync(() => db.select(db.reminders).getSingle()))!;
    expect(find.textContaining('Snoozed until'), findsOneWidget);
    expect(r.offsetMinutes, isNull);
    expect(DateTime.fromMillisecondsSinceEpoch(r.at!, isUtc: true), testNow.toUtc().add(const Duration(hours: 1)));
  });

  testWidgets('chi tiết: đổi tên, ưu tiên, xóa có xác nhận', (tester) async {
    final c = await pumpApp(tester, size: phone, locale: en, seed: seedDay);
    await tester.tap(find.text('Buy a gift'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('itemTitle')), 'Buy a birthday gift');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.tap(find.byKey(const Key('itemPriority')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('itemPriority')), matching: find.text('High')), findsOneWidget);
    await tester.tap(find.byKey(const Key('itemDone')));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget, reason: 'chip trạng thái chạm để xong');
    await tester.tap(find.byKey(const Key('itemDone')));
    await tester.pumpAndSettle();
    expect(find.text('Not done'), findsOneWidget);

    await tester.tap(find.byKey(const Key('itemDelete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this item?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('itemTitle')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Buy a birthday gift'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high), findsOneWidget);

    await tester.tap(find.text('Buy a birthday gift'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('itemDelete')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Buy a birthday gift'), findsNothing);
    expect(find.text('Today'), findsWidgets);
    // Mỗi thay đổi nằm trong outbox chờ sync (app đang offline).
    expect(await tester.runAsync(() => c.read(syncEngineProvider).pendingCount()), greaterThanOrEqualTo(7));
  });

  testWidgets('chi tiết: Việc chuẩn bị (Figma 04): thêm, đánh dấu, sửa, xóa + Hoàn tác', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 1200), locale: const Locale('vi'), region: 'VN', seed: seedDay);
    await tester.tap(find.text('Buy a gift'));
    await tester.pumpAndSettle();
    expect(find.text('Việc chuẩn bị'), findsOneWidget);
    expect(find.byKey(const Key('checklistCount')), findsNothing);
    for (final t in ['Tổng hợp phản hồi', 'Chuẩn bị bản trình bày']) {
      await tester.enterText(find.byKey(const Key('checklistAdd')), t);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    expect(tester.widget<Text>(find.byKey(const Key('checklistCount'))).data, '0/2');
    await tester.tap(find.text('Tổng hợp phản hồi'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('checklistCount'))).data, '1/2');

    await tester.longPress(find.text('Chuẩn bị bản trình bày'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('checklistText')), 'Chuẩn bị slide');
    await tester.tap(find.byKey(const Key('checklistSave')));
    await tester.pumpAndSettle();
    expect(find.text('Chuẩn bị slide'), findsOneWidget);

    await tester.longPress(find.text('Tổng hợp phản hồi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('checklistRemove')));
    await tester.pumpAndSettle();
    expect(find.text('Tổng hợp phản hồi'), findsNothing);
    expect(tester.widget<Text>(find.byKey(const Key('checklistCount'))).data, '0/1');
    await tester.tap(find.byKey(const Key('checklistUndo')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('checklistCount'))).data, '1/2');

    final db = c.read(appDatabaseProvider);
    final row = (await tester.runAsync(() async => (await db.select(db.items).get()).firstWhere((i) => i.title == 'Buy a gift')))!;
    expect(row.checklist, '[{"text":"Tổng hợp phản hồi","done":true},{"text":"Chuẩn bị slide","done":false}]');
  });

  testWidgets('tiếng Việt: nhóm, nút và giờ theo locale', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('vi'), seed: seedDay);
    for (final t in ['Quá hạn', 'Chưa đặt giờ', 'Cả ngày', '14:30']) {
      expect(find.text(t), findsWidgets, reason: t);
    }
  });

  // Pseudo-locale + chữ 1,3x ở màn hẹp nhất: Hôm nay có dữ liệu và màn chi tiết không tràn layout.
  testWidgets('pseudo-locale + chữ lớn: Hôm nay và chi tiết không vỡ ở 320dp', (tester) async {
    await pumpApp(tester, size: const Size(320, 640), locale: pseudoLocale, textScale: 1.3, seed: seedDay);
    await tester.scrollUntilVisible(find.text('Buy a gift'), 100);
    await tester.tap(find.text('Buy a gift'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('itemPriority')), findsOneWidget);
  });
}
