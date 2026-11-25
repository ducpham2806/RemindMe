import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_client/data/reminders.dart';
import 'package:remindme_platform/remindme_platform.dart';

import 'helpers.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-3')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('me-bell')));
  await tester.tap(find.byKey(const Key('me-bell')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Thông báo & nhắc: mốc nhắc mặc định dùng cho Thêm nhanh; giờ việc cả ngày lưu trên máy', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 844), locale: const Locale('en'));
    await _open(tester);
    expect(find.text('Notifications are on'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('notifAllDayTime')), matching: find.text('9:00 AM')), findsOneWidget);

    await tester.tap(find.byKey(const Key('notifDefaultOffset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('defaultReminder--10')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('notifDefaultOffset')), matching: find.text('10 minutes before')), findsOneWidget);
    final prefs = c.read(localPrefsProvider);
    expect(await tester.runAsync(() => prefs.get(defaultReminderPref)), '-10');

    // Thêm nhanh dùng mốc vừa chọn.
    await tester.tap(find.byKey(const Key('notifDone')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Add a task or reminder').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Dentist tomorrow 8am');
    await tester.pump();
    expect(find.descendant(of: find.byKey(const Key('chipReminder')), matching: find.text('10 minutes before')), findsOneWidget);
  });

  testWidgets('thông báo bị tắt: thẻ cảnh báo + nút cho phép', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), locale: const Locale('vi'),
        health: const NotificationHealth(notificationsAllowed: false));
    await _open(tester);
    expect(find.text('Thông báo đang tắt'), findsOneWidget);
    expect(find.byKey(const Key('notifAllow')), findsOneWidget);
  });

  testWidgets('đổi giờ nhắc việc cả ngày → lập lịch lại theo giờ mới', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 844), locale: const Locale('en'), seed: (r) async {
      await r.create(title: 'Pay rent', startDate: '2026-12-03', tz: 'Asia/Ho_Chi_Minh', reminderOffsets: const [0]);
    });
    await settleReminders(tester);
    expect(testOs.pending.values.single.fireAtUtc, DateTime.utc(2026, 12, 3, 2), reason: '09:00 giờ VN mặc định');
    await tester.runAsync(() => c.read(localPrefsProvider).set(allDayTimePref, '07:30'));
    await settleReminders(tester);
    expect(testOs.pending.values.single.fireAtUtc, DateTime.utc(2026, 12, 3, 0, 30));
  });

  testWidgets('vi: giờ yên lặng (C51): bật → nhắc 23:30 lập lịch im lặng, nhắc ban ngày vẫn kêu; đổi giờ kết thúc; tắt → kêu lại', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 1200), locale: const Locale('vi'), region: 'VN', seed: (r) async {
      const tz = 'Asia/Ho_Chi_Minh';
      await r.create(title: 'Uống thuốc tối', startsAt: DateTime.utc(2026, 12, 2, 16, 30), tz: tz, reminderOffsets: const [0]); // 23:30
      await r.create(title: 'Họp', startsAt: DateTime.utc(2026, 12, 2, 7), tz: tz, reminderOffsets: const [0]); // 14:00
    });
    await settleReminders(tester);
    expect(testOs.pending.values.where((n) => n.silent), isEmpty);
    await _open(tester);
    expect(tester.widget<Text>(find.byKey(const Key('notifQuietSummary'))).data, 'Đang tắt · Khung gợi ý 22:00–07:00');
    await tester.ensureVisible(find.byKey(const Key('notifQuiet')));
    await tester.tap(find.byKey(const Key('notifQuiet')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('notifQuietSummary'))).data, '22:00–07:00 · Nhắc vẫn hiện nhưng không kêu');
    expect(find.byKey(const Key('notifQuietStart')), findsOneWidget);
    await settleReminders(tester);
    final silent = {for (final n in testOs.pending.values) n.title: n.silent};
    expect(silent, {'Uống thuốc tối': true, 'Họp': false});

    // Đổi giờ bắt đầu sang 23:45 (lưu trực tiếp như sau khi chọn giờ): 23:30 không còn trong khung.
    await tester.runAsync(() => c.read(localPrefsProvider).set(quietHoursPref, '23:45-07:00'));
    await settleReminders(tester);
    expect(testOs.pending.values.where((n) => n.silent), isEmpty);

    await tester.tap(find.byKey(const Key('notifQuiet')));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => c.read(localPrefsProvider).get(quietHoursOnPref)), '0');
  });
}
