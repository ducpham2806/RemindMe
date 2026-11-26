import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_platform/remindme_platform.dart';

import 'helpers.dart';
import 'quick_add_test.dart' show openQuickAdd;

const phone = Size(390, 844);
const en = Locale('en');

void main() {
  testWidgets('trở lại ở múi giờ khác: nhắc cả ngày xa 20 ngày đổi giờ kêu và Hôm nay đổi ngày', (tester) async {
    var now = DateTime(2026, 12, 1, 10);
    final c = await pumpApp(tester, size: phone, now: () => now, overrides: [
      readDeviceTimeZoneProvider.overrideWithValue(() async => 'Europe/London'),
    ], seed: (repo) async {
      await repo.create(title: 'Checkup', startDate: '2026-12-21', reminderOffsets: [0]);
    });
    await settleReminders(tester);
    expect(c.read(todayWindowProvider).localDate, '2026-12-01');
    expect(testOs.pending.values.single.fireAtUtc, DateTime.utc(2026, 12, 21, 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2026, 12, 2, 10);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await settleReminders(tester);
    expect(c.read(todayWindowProvider).localDate, '2026-12-02');
    expect(c.read(deviceTimeZoneProvider), 'Europe/London');
    expect(testOs.pending.values.single.fireAtUtc, DateTime.utc(2026, 12, 21, 9));
  });

  testWidgets('để app mở qua nửa đêm: Hôm nay tự chuyển sang ngày mới', (tester) async {
    var now = DateTime(2026, 12, 1, 23, 59);
    final c = await pumpApp(tester, size: phone, now: () => now, overrides: [
      readDeviceTimeZoneProvider.overrideWithValue(() async => 'Asia/Ho_Chi_Minh'),
    ]);
    expect(c.read(todayWindowProvider).localDate, '2026-12-01');
    now = DateTime(2026, 12, 2);
    await tester.pump(const Duration(minutes: 1));
    await settleReminders(tester);
    expect(c.read(todayWindowProvider).localDate, '2026-12-02');
  });

  testWidgets('Quick Add có giờ → nhắc đúng giờ mặc định, lập lịch với OS, hỏi quyền 1 lần', (tester) async {
    await pumpApp(tester, size: phone, locale: en, health: const NotificationHealth(notificationsAllowed: false));
    await openQuickAdd(tester, 'Dentist at 5pm');
    expect(find.byKey(const Key('chipReminder')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quickAddSave')));
    await settleReminders(tester);
    final n = testOs.pending.values.single;
    expect(n.title, 'Dentist');
    expect(n.fireAtUtc, DateTime(2026, 12, 1, 17).toUtc());
    expect(n.body, '5:00\u202fPM', reason: 'CLDR dùng khoảng trắng hẹp không ngắt trước PM');
    expect(testOs.permissionRequests, 1);
  });

  testWidgets('chi tiết: thêm "Trước 10 phút", bỏ nhắc → OS cập nhật theo', (tester) async {
    await pumpApp(tester, size: phone, locale: en, seed: (repo) async {
      await repo.create(title: 'Meeting', startsAt: DateTime(2026, 12, 1, 15).toUtc(), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0]);
    });
    await settleReminders(tester);
    expect(testOs.pending, hasLength(1));
    await tester.tap(find.text('Meeting'));
    await tester.pumpAndSettle();
    expect(find.text('At time of item'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reminderAdd')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 minutes before').last);
    await settleReminders(tester);
    expect(testOs.pending.values.map((n) => n.fireAtUtc).toSet(),
        {DateTime(2026, 12, 1, 15).toUtc(), DateTime(2026, 12, 1, 14, 50).toUtc()});
    expect(testOs.pending.values.firstWhere((n) => n.fireAtUtc.minute == 50).body, 'In 10 minutes · 3:00\u202fPM');
    await tester.tap(find.descendant(of: find.byKey(const Key('reminder-0')), matching: find.byTooltip('Remove reminder')));
    await settleReminders(tester);
    expect(testOs.pending.values.single.fireAtUtc, DateTime(2026, 12, 1, 14, 50).toUtc());
  });

  testWidgets('thiếu quyền + đã có nhắc → thẻ "Nhắc nhở có thể không kêu"; Cho phép thì mất thẻ', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('vi'),
        health: const NotificationHealth(notificationsAllowed: true, exactAlarmsAllowed: false), seed: (repo) async {
      await repo.create(title: 'Họp', startsAt: DateTime(2026, 12, 1, 15).toUtc(), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0]);
    });
    await settleReminders(tester);
    expect(find.text('Nhắc nhở có thể không kêu'), findsOneWidget);
    await tester.tap(find.text('Cho phép'));
    await settleReminders(tester);
    expect(find.byKey(const Key('reminderHealthCard')), findsNothing);
  });

  testWidgets('bấm "Xong" trên thông báo khi app đang mở → item xong, hủy thông báo', (tester) async {
    final taps = StreamController<NotificationTap>();
    addTearDown(taps.close);
    await pumpApp(tester, size: phone, locale: en, taps: taps.stream, seed: (repo) async {
      await repo.create(title: 'Pay rent', startsAt: DateTime(2026, 12, 1, 15).toUtc(), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0]);
    });
    await settleReminders(tester);
    final n = testOs.pending.values.single;
    taps.add(NotificationTap(actionId: NotificationActionIds.done, payload: n.payload));
    await settleReminders(tester);
    expect(find.text('Done'), findsOneWidget);
    expect(testOs.pending, isEmpty);
  });

  testWidgets('bấm vào thông báo → mở chi tiết item', (tester) async {
    final taps = StreamController<NotificationTap>();
    addTearDown(taps.close);
    await pumpApp(tester, size: phone, locale: en, taps: taps.stream, seed: (repo) async {
      await repo.create(title: 'Pay rent', startsAt: DateTime(2026, 12, 1, 15).toUtc(), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: [0]);
    });
    await settleReminders(tester);
    taps.add(NotificationTap(payload: testOs.pending.values.single.payload));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('itemTitle')), findsOneWidget);
  });

  testWidgets('đổi ngôn ngữ app → thông báo đã lập lịch dùng chuỗi mới', (tester) async {
    await pumpApp(tester, size: phone, locale: const Locale('vi'), seed: (repo) async {
      final id = await repo.create(title: 'Họp', startsAt: DateTime(2026, 12, 1, 15).toUtc(), tz: 'Asia/Ho_Chi_Minh');
      await repo.addReminder(id, offsetMinutes: -60);
    });
    await settleReminders(tester);
    expect(testOs.pending.values.single.body, '1 giờ nữa · 15:00');
    expect(CivilDate(2026, 12, 1).weekday, DateTime.tuesday);
  });
}
