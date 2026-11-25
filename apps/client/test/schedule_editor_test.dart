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
    expect(find.byKey(const Key('dtMonth')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('dtMonth'))).data, 'December 2026');
    await tester.tap(find.byKey(const Key('dtDay-2026-12-05')));
    await tester.pump();
    expect(find.text('Confirm · 12/5, all day'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dtConfirm')));
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
    expect(find.text('Working days'), findsOneWidget);
    expect(find.text('Every day at 6:00 PM'), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
    await tester.tap(find.byKey(const Key('repeat-weekly')));
    await tester.pump();
    expect(find.text('Apply · Weekly'), findsOneWidget);
    await tester.tap(find.byKey(const Key('repeatApply')));
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
    await tester.tap(find.byKey(const Key('repeatLunar')));
    await tester.pumpAndSettle();
    // 1/12/2026 = 23/10 âm lịch (tháng 10 âm bắt đầu 9/11/2026): mặc định "Ngày riêng" theo ngày đã chọn.
    expect(find.text('Âm lịch Việt Nam'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('lunarDay')), matching: find.text('23')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('lunarMonth')), matching: find.text('10')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('lunarSummary')), matching: find.text('Ngày 23 tháng 10 âm lịch hằng năm')), findsOneWidget);
    await tester.tap(find.byKey(const Key('lunarApply')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('repeat-current')), findsOneWidget);
    await tester.tap(find.byKey(const Key('repeatApply')));
    await settleReminders(tester);
    expect(find.descendant(of: find.byKey(const Key('repeatRow')), matching: find.text('Ngày 23 tháng 10 âm lịch hằng năm')), findsOneWidget);
  });

  for (final (region, byday, workdays) in [('VN', 'MO,TU,WE,TH,FR', 'VN'), ('SA', 'MO,TU,WE,TH,SU', 'SA')]) {
    testWidgets('ngày làm việc ở $region: BYDAY theo cuối tuần CLDR + workdays_region', (tester) async {
      final c = await pumpApp(tester, size: phone, locale: const Locale('vi'), region: region, seed: seedTimed);
      await openDetail(tester);
      await tester.tap(find.byKey(const Key('repeatRow')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('repeat-workdays')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('repeatApply')));
      await settleReminders(tester);
      final db = c.read(appDatabaseProvider);
      final rec = (await tester.runAsync(() => db.select(db.recurrences).getSingle()))!;
      expect(rec.rrule, 'FREQ=WEEKLY;BYDAY=$byday');
      expect(rec.workdaysRegion, workdays);
      expect(find.descendant(of: find.byKey(const Key('repeatRow')), matching: find.text('Các ngày làm việc')), findsOneWidget);
    });
  }

  testWidgets('âm lịch "Ngày rằm": hằng tháng ngày 15, item dời về rằm kế tiếp', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('vi'), region: 'VN', seed: seedTimed);
    await openDetail(tester);
    await tester.tap(find.byKey(const Key('repeatRow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repeatLunar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lunarPreset-full')));
    await tester.pump();
    expect(find.descendant(of: find.byKey(const Key('lunarMonth')), matching: find.text('Mọi tháng')), findsOneWidget);
    // Rằm tháng 11 âm 2026 = 23/12/2026.
    expect(find.textContaining('Lần tới: 23 thg 12'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lunarApply')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repeatApply')));
    await settleReminders(tester);
    expect(find.descendant(of: find.byKey(const Key('repeatRow')), matching: find.text('Ngày 15 âm lịch hằng tháng')), findsOneWidget);
    expect(chip('pickDate', '23 thg 12'), findsOneWidget);
  });

  testWidgets('lặp tùy chỉnh: mỗi 2 tuần vào T2, T4; kết thúc sau 5 lần', (tester) async {
    final c = await pumpApp(tester, size: phone, locale: const Locale('en'), seed: seedTimed);
    await openDetail(tester);
    await tester.tap(find.byKey(const Key('repeatRow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repeatCustom')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customPlus')));
    await tester.tap(find.byKey(const Key('customDay-MO')));
    await tester.tap(find.byKey(const Key('customDay-WE')));
    await tester.tap(find.byKey(const Key('customDay-TU')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('customPreview'))).data, 'Every 2 weeks on Mon, Wed');
    await tester.tap(find.byKey(const Key('customApply')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('repeatEnd')));
    await tester.tap(find.byKey(const Key('repeatEnd')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repeatEnd-count')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('repeatEndCount')), '5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Ends: after 5 times'), findsOneWidget);
    await tester.tap(find.byKey(const Key('repeatApply')));
    await settleReminders(tester);
    final db = c.read(appDatabaseProvider);
    final rec = (await tester.runAsync(() => db.select(db.recurrences).getSingle()))!;
    expect(rec.rrule, 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=5');
    expect(find.descendant(of: find.byKey(const Key('repeatRow')), matching: find.text('Every 2 weeks on Mon, Wed, 5 times')), findsOneWidget);
  });

  testWidgets('hoãn nhắc từ chi tiết: việc sắp tới giờ → Hoãn nhắc 30 phút ghi snoozed_until', (tester) async {
    // 10:30 giờ VN (03:30Z), nhắc đúng giờ; testNow cùng ngày, sau giờ hẹn (máy UTC) hoặc trước 30 phút (máy giờ VN).
    final c = await pumpApp(tester, size: phone, locale: const Locale('vi'), region: 'VN', seed: (r) =>
        r.create(title: 'Gym', startsAt: DateTime.utc(2026, 12, 1, 3, 30), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: const [0]));
    await openDetail(tester);
    await tester.tap(find.byKey(const Key('itemSnooze')));
    await tester.pumpAndSettle();
    // Giờ hiển thị theo múi giờ VN của app, testNow theo giờ máy chạy test.
    String vn(Duration d) {
      final t = testNow.toUtc().add(const Duration(hours: 7)).add(d);
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    expect(find.text('Hoãn đến ${vn(const Duration(minutes: 10))}'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('snooze-evening')), matching: find.text('20:00')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('snooze-morning')), matching: find.textContaining('08:00')), findsOneWidget);
    await tester.tap(find.byKey(const Key('snooze-30m')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('snoozeApply')));
    await settleReminders(tester);
    expect(find.text('Đã hoãn đến ${vn(const Duration(minutes: 30))}'), findsOneWidget);
    final db = c.read(appDatabaseProvider);
    final r = (await tester.runAsync(() => db.select(db.reminders).getSingle()))!;
    expect(DateTime.fromMillisecondsSinceEpoch(r.snoozedUntil!, isUtc: true), testNow.toUtc().add(const Duration(minutes: 30)));
  });
}
