import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';

import 'helpers.dart';

Finder inDay(String iso, Finder f) => find.descendant(of: find.byKey(Key('calendarDay-$iso')), matching: f);

void main() {
  testWidgets('vi, VN: lưới tháng có chấm ở ngày có việc, ngày âm mùng 1; tháng sau có Tết Dương lịch là ngày nghỉ lễ', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), locale: const Locale('vi'), region: 'VN', seed: (repo) async {
      await repo.create(title: 'Nộp hồ sơ', startDate: '2026-12-03');
    });
    await tester.tap(find.text('Lịch').last);
    await tester.pumpAndSettle();
    expect(find.text('tháng 12 năm 2026'), findsOneWidget);
    expect(inDay('2026-12-03', find.byIcon(Icons.circle)), findsOneWidget);
    expect(inDay('2026-12-04', find.byIcon(Icons.circle)), findsNothing);
    // Mùng 1 âm lịch trong tháng: hiện "1/tháng".
    final cal = LunarCalendar(LunarSystem.vi);
    final first = [for (var d = 1; d <= 31; d++) CivilDate(2026, 12, d)].firstWhere((d) => cal.fromSolar(d).day == 1);
    expect(inDay(first.toIso(), find.text('1/${cal.fromSolar(first).month}')), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendarDay-2026-12-03')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('calendarDayList')), matching: find.text('Nộp hồ sơ')), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendarNext')));
    await tester.pumpAndSettle();
    expect(find.text('tháng 1 năm 2027'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendarDay-2027-01-01')));
    await tester.pumpAndSettle();
    expect(find.text('Tết Dương lịch'), findsOneWidget);
    expect(find.text('Ngày nghỉ lễ'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('calendarDay-2027-01-01'))).label,
      allOf(contains('Tết Dương lịch'), contains('âm lịch')),
    );

    await tester.tap(find.byKey(const Key('calendarToday')));
    await tester.pumpAndSettle();
    expect(find.text('tháng 12 năm 2026'), findsOneWidget);
  });

  testWidgets('en, US: 4/7/2027 là Chủ nhật → nghỉ bù thứ Hai 5/7; không có ngày âm; ngày trống có thông báo', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), region: 'US');
    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.byKey(const Key('calendarNext')));
      await tester.pumpAndSettle();
    }
    expect(find.text('July 2027'), findsOneWidget);
    expect(find.textContaining('/'), findsNothing, reason: 'tiếng Anh không có hệ âm lịch');
    await tester.tap(find.byKey(const Key('calendarDay-2027-07-05')));
    await tester.pumpAndSettle();
    expect(find.text('Independence Day'), findsOneWidget);
    expect(find.text('Substitute day off'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendarDay-2027-07-06')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing planned for this day'), findsOneWidget);
  });

  testWidgets('vùng chưa có gói ngày lễ (JP) và chữ lớn ở 320dp: lịch vẫn hiện, không vỡ bố cục', (tester) async {
    await pumpApp(tester, size: const Size(320, 640), locale: const Locale('en', 'XA'), textScale: 1.3, region: 'JP');
    await tester.tap(find.byKey(const Key('nav-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendarDay-2026-12-01')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
