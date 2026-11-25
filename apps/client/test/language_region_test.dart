import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_client/features/me/language_region_screen.dart';
import 'package:remindme_core/remindme_core.dart';

import 'helpers.dart';

void main() {
  tearDown(HolidayCalendars.clear);

  testWidgets('en, máy ở US: chọn ngày lễ Việt Nam + âm lịch VN → lịch có Tết và ngày âm; Không dùng thì tắt', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 844), region: 'US');
    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('me-globe')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('me-globe')));
    await tester.pumpAndSettle();
    expect(find.text('Same as this device (United States) · Weekend: Saturday, Sunday'), findsOneWidget);
    expect(find.text('Same as app language (none)', skipOffstage: false), findsOneWidget);
    expect(find.text('Asia/Ho_Chi_Minh · UTC+07 · from this device'), findsOneWidget);
    await tester.tap(find.byKey(const Key('langRegionHolidays')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('holidayRegion-VN')));
    await tester.pumpAndSettle();
    expect(find.text('Vietnam · Weekend: Saturday, Sunday'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('langRegionCalendar')), 100,
        scrollable: find.descendant(of: find.byType(LanguageRegionScreen), matching: find.byType(Scrollable)).first);
    await tester.tap(find.byKey(const Key('langRegionCalendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendarSystem-lunar_vi')));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => c.read(localPrefsProvider).get(holidayRegionPref)), 'VN');

    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendarNext')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendarNext')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendarDay-2027-02-06')));
    await tester.pumpAndSettle();
    expect(find.text('Lunar New Year'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('calendarDay-2027-02-06')), matching: find.text('1/1')), findsOneWidget);

    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('langRegionHolidays')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('holidayRegion-none')));
    await tester.pumpAndSettle();
    expect(find.text('None'), findsOneWidget, reason: 'không dùng ngày lễ thì không ghi ngày nghỉ cuối tuần');
    await tester.scrollUntilVisible(find.byKey(const Key('langRegionCalendar')), 100,
        scrollable: find.descendant(of: find.byType(LanguageRegionScreen), matching: find.byType(Scrollable)).first);
    await tester.tap(find.byKey(const Key('langRegionCalendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendarSystem-none')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();
    expect(find.text('Lunar New Year'), findsNothing);
    expect(find.textContaining('/'), findsNothing);
  });
}
