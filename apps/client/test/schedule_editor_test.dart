import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_data/remindme_data.dart';

import 'helpers.dart';

const phone = Size(390, 844);

// Kiểm qua giao diện (chip ngày/giờ, phụ đề Lặp lại), không đọc DB bằng runAsync: transaction lập lịch nhắc chạy trong
// zone fake-async, đọc DB từ zone thật lúc đó sẽ kẹt khóa.
void main() {
  Future<void> seedNoDate(ItemsRepository r) => r.create(title: 'Gym');
  Future<void> seedTimed(ItemsRepository r) => r.create(title: 'Gym', startsAt: DateTime.utc(2026, 12, 1, 11), tz: 'Asia/Ho_Chi_Minh');

  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
  }

  Finder chip(String key, String text) => find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

  testWidgets('chọn ngày cho việc chưa có ngày → việc cả ngày, có nút Thêm giờ', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('en'), seed: seedNoDate);
    await openDetail(tester);
    expect(chip('pickDate', 'Add date'), findsOneWidget);
    expect(find.text('Set a date to repeat'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pickDate')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.tap(find.text('OK'));
    await settleReminders(tester);
    expect(chip('pickDate', 'Dec 5'), findsOneWidget);
    expect(chip('pickTime', 'Add time'), findsOneWidget);
    expect(find.text('Doesn’t repeat'), findsOneWidget);
  });

  testWidgets('chọn lặp "Every Tue"; bỏ giờ → cả ngày; bỏ ngày → bỏ cả lặp', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('en'), seed: seedTimed);
    await openDetail(tester);
    expect(chip('pickDate', 'Dec 1'), findsOneWidget);
    expect(chip('pickTime', '6:00 PM'), findsOneWidget, reason: '11:00Z = 18:00 giờ VN (máy test giả lập múi giờ VN)');
    await tester.tap(find.byKey(const Key('repeatRow')));
    await tester.pumpAndSettle();
    expect(find.text('Every working day'), findsOneWidget);
    await tester.tap(find.text('Every Tue'));
    await settleReminders(tester);
    expect(find.descendant(of: find.byKey(const Key('repeatRow')), matching: find.text('Every Tue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('removeTime')));
    await settleReminders(tester);
    expect(chip('pickTime', 'Add time'), findsOneWidget);

    await tester.tap(find.byKey(const Key('removeDate')));
    await settleReminders(tester);
    expect(chip('pickDate', 'Add date'), findsOneWidget);
    expect(find.text('Set a date to repeat'), findsOneWidget);
  });

  testWidgets('tiếng Việt: lựa chọn lặp âm lịch theo ngày âm của ngày đã chọn', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('vi'), region: 'VN', seed: seedTimed);
    await openDetail(tester);
    await tester.tap(find.byKey(const Key('repeatRow')));
    await tester.pumpAndSettle();
    // 1/12/2026 = 23/10 âm lịch (tháng 10 âm bắt đầu 9/11/2026).
    expect(find.text('Ngày 23 âm lịch hằng tháng'), findsOneWidget);
    await tester.tap(find.text('Ngày 23 tháng 10 âm lịch hằng năm'));
    await settleReminders(tester);
    expect(find.descendant(of: find.byKey(const Key('repeatRow')), matching: find.text('Ngày 23 tháng 10 âm lịch hằng năm')), findsOneWidget);
  });

  for (final (region, byday, workdays) in [('VN', 'MO,TU,WE,TH,FR', 'VN'), ('SA', 'MO,TU,WE,TH,SU', 'SA')]) {
    testWidgets('ngày làm việc ở $region: BYDAY theo cuối tuần CLDR + workdays_region', (tester) async {
      final c = await pumpApp(tester, size: phone, locale: const Locale('vi'), region: region, seed: seedTimed);
      await openDetail(tester);
      await tester.tap(find.byKey(const Key('repeatRow')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Các ngày làm việc'));
      await settleReminders(tester);
      final db = c.read(appDatabaseProvider);
      final rec = (await tester.runAsync(() => db.select(db.recurrences).getSingle()))!;
      expect(rec.rrule, 'FREQ=WEEKLY;BYDAY=$byday');
      expect(rec.workdaysRegion, workdays);
      expect(find.descendant(of: find.byKey(const Key('repeatRow')), matching: find.text('Các ngày làm việc')), findsOneWidget);
    });
  }
}
