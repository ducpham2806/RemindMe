import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

import 'helpers.dart';

/// Gói tổng hợp: thứ Năm 3/12 và thứ Sáu 4/12/2026 là ngày nghỉ (testNow = 1/12/2026).
const _pack = '{"region": "ZZ", "version": 1, "holidays": ['
    '{"id": "founders", "rule": {"type": "fixed", "month": 12, "day": 3}, "days": 2, "names": {"en": "Founders Day", "vi": "Ngày Lập quốc"}},'
    '{"id": "fair", "rule": {"type": "fixed", "month": 12, "day": 2}, "day_off": false, "names": {"en": "Fair"}}]}';

void main() {
  late HolidayCalendar cal;
  setUp(() {
    cal = HolidayCalendar.parse(_pack);
    HolidayCalendars.register(cal);
  });
  tearDown(HolidayCalendars.clear);

  Future<(String, String, String)> seed(tester, repo) async {
    final timed = await repo.create(title: 'Report', startsAt: DateTime.utc(2026, 12, 3, 2), tz: 'Asia/Ho_Chi_Minh') as String;
    final allDay = await repo.create(title: 'Pay rent', startDate: '2026-12-03') as String;
    final fair = await repo.create(title: 'On fair day', startDate: '2026-12-02') as String;
    return (timed, allDay, fair);
  }

  testWidgets('en: ngày nghỉ lễ có việc → dời sang ngày làm việc kế tiếp giữ giờ, Hoàn tác đưa về', (tester) async {
    late (String, String, String) ids;
    final c = await pumpApp(tester, size: const Size(390, 844), region: 'ZZ', seed: (repo) async => ids = await seed(tester, repo), overrides: [
      holidayCalendarProvider.overrideWith((ref) async => cal),
    ]);
    expect(find.text('Dec 3 is a public holiday: Founders Day'), findsOneWidget);
    expect(find.text('You have 2 tasks planned for that day.'), findsOneWidget, reason: 'ngày kỷ niệm (không nghỉ) không gợi ý');
    await tester.tap(find.text('Move to Dec 7'));
    await settleReminders(tester);
    final repo = c.read(itemsRepositoryProvider);
    Future<(ItemView?, ItemView?)> load() async => (await tester.runAsync(() async => (await repo.getItem(ids.$1), await repo.getItem(ids.$2))))!;
    var (timed, allDay) = await load();
    expect(timed!.startsAt, DateTime.utc(2026, 12, 7, 2));
    expect(allDay!.startDate, '2026-12-07');
    expect(find.byKey(const Key('holidayHintCard')), findsNothing);
    expect(find.text('Moved 2 tasks'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleReminders(tester);
    (timed, allDay) = await load();
    expect(timed!.startsAt, DateTime.utc(2026, 12, 3, 2));
    expect(allDay!.startDate, '2026-12-03');
    expect(find.byKey(const Key('holidayHintCard')), findsOneWidget);
  });

  testWidgets('vi: "Để nguyên" thì ẩn và không hỏi lại ngày đó', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 844), locale: const Locale('vi'), region: 'ZZ', seed: (repo) => seed(tester, repo),
        overrides: [holidayCalendarProvider.overrideWith((ref) async => cal)]);
    expect(find.text('Bạn có 2 việc đang hẹn vào ngày này.'), findsOneWidget);
    expect(find.textContaining('Ngày Lập quốc'), findsOneWidget);
    await tester.tap(find.byKey(const Key('holidayHintKeep')));
    await settleReminders(tester);
    expect(find.byKey(const Key('holidayHintCard')), findsNothing);
    final dismissed = await tester.runAsync(() => c.read(localPrefsProvider).getSet(holidayHintDismissedPref));
    expect(dismissed, {'2026-12-03'});
  });
}
