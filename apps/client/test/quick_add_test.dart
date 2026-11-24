import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/app.dart' show pseudoLocale;
import 'package:remindme_client/data/providers.dart';

import 'helpers.dart';

const phone = Size(390, 844);

Future<void> openQuickAdd(WidgetTester tester, String text) async {
  await tester.tap(find.byKey(const Key('quickAddFab')));
  await tester.pumpAndSettle();
  // Gói NLU tải từ asset (bất đồng bộ thật).
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('quickAddField')), text);
  await tester.pumpAndSettle();
}

Future<List<Map<String, Object?>>> rows(WidgetTester tester, ProviderContainer c, String sql) async =>
    (await tester.runAsync(() => c.read(appDatabaseProvider).customSelect(sql, variables: <Variable<Object>>[]).get()))!
        .map((r) => r.data)
        .toList();

void main() {
  testWidgets('en: chip thời điểm từ câu tự nhiên, lưu vào Hôm nay theo giờ đã hiểu', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('en'));
    await openQuickAdd(tester, 'Dentist at 5pm #health');
    expect(find.descendant(of: find.byKey(const Key('chipWhen')), matching: find.text('5:00 PM')), findsOneWidget);
    expect(find.text('health'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quickAddSave')));
    await tester.pumpAndSettle();
    expect(find.text('Dentist'), findsOneWidget);
    expect(find.text('5:00 PM'), findsOneWidget);
  });

  testWidgets('giờ mơ hồ: hiện "Ý bạn là", chọn lựa chọn khác thì chip đổi theo', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('en'));
    await openQuickAdd(tester, 'call mom at 3');
    expect(find.text('Did you mean'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('chipWhen')), matching: find.text('3:00 PM')), findsOneWidget);
    await tester.tap(find.byKey(const Key('amb-0-0')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('chipWhen')), matching: find.textContaining('3:00 AM')), findsOneWidget);
  });

  testWidgets('nhiều việc trong 1 câu: "Tìm thấy 2 mục", Lưu tất cả', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('en'));
    await openQuickAdd(tester, 'call John at 3pm and email Sara at 5pm');
    expect(find.text('Found 2 items'), findsOneWidget);
    await tester.tap(find.text('Save all'));
    await tester.pumpAndSettle();
    expect(find.text('Call John'), findsOneWidget);
    expect(find.text('Email Sara'), findsOneWidget);
  });

  testWidgets('lặp: chip "Every day", lưu kèm hàng recurrences, Hôm nay có biểu tượng lặp', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('en'));
    await openQuickAdd(tester, 'take pills every day at 8pm');
    expect(find.text('Every day'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quickAddSave')));
    await tester.pumpAndSettle();
    expect(find.text('Take pills'), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsOneWidget);
  });

  testWidgets('vi: "đi chùa rằm" → chip âm lịch, lưu ngày rằm kế tiếp và calendar lunar_vi', (tester) async {
    final c = await pumpApp(tester, size: phone, locale: const Locale('vi'), region: 'VN');
    await openQuickAdd(tester, 'đi chùa rằm');
    expect(find.text('Ngày 15 âm lịch hằng tháng'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quickAddSave')));
    await tester.pumpAndSettle();
    final items = await rows(tester, c, 'SELECT title, start_date, all_day FROM items');
    // testNow 1/12/2026: rằm tháng 10 âm (23/11) đã qua; tháng 11 âm bắt đầu 9/12 (sóc) nên rằm = 23/12/2026.
    expect(items.single, {'title': 'Đi chùa', 'start_date': '2026-12-23', 'all_day': 1});
    final rec = await rows(tester, c, 'SELECT kind, calendar FROM recurrences');
    expect(rec.single['kind'], 'calendar');
    expect(rec.single['calendar'], contains('lunar_vi'));
  });

  testWidgets('vi: câu có giờ + ngày tương đối', (tester) async {
    final c = await pumpApp(tester, size: phone, locale: const Locale('vi'), region: 'VN');
    await openQuickAdd(tester, 'Mai 8h sáng họp khách');
    expect(find.descendant(of: find.byKey(const Key('chipWhen')), matching: find.textContaining('08:00')), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final items = await rows(tester, c, 'SELECT title, starts_at, tz FROM items');
    expect(items.single['title'], 'Họp khách');
    expect(items.single['tz'], 'Asia/Ho_Chi_Minh');
    expect(items.single['starts_at'], DateTime(2026, 12, 2, 8).toUtc().millisecondsSinceEpoch);
  });

  testWidgets('pseudo-locale + chữ 1,3x ở 320dp: chip + "Ý bạn là" + nhiều việc không tràn', (tester) async {
    await pumpApp(tester, size: const Size(320, 640), locale: pseudoLocale, textScale: 1.3);
    await openQuickAdd(tester, 'call mom at 3 every Monday and Wednesday #family !! and email Sara at 5pm tomorrow');
    expect(find.byKey(const Key('quickAddSave')), findsOneWidget);
  });
}
