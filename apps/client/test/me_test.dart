import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';

import 'helpers.dart';

void main() {
  testWidgets('Tôi: chọn ngôn ngữ và giao diện trong app → đổi ngay, lưu trên máy; Theo máy thì trở lại', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 844));
    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pumpAndSettle();
    expect(find.text('Your space'), findsOneWidget);
    expect(find.textContaining('Coming soon'), findsWidgets, reason: 'mục chưa làm hiện "Sắp có"');

    await tester.scrollUntilVisible(find.byKey(const Key('appTheme-dark')), 100);
    await tester.tap(find.byKey(const Key('appLanguage-vi')));
    await tester.pumpAndSettle();
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget, reason: 'cả thanh dưới đổi ngôn ngữ');

    await tester.tap(find.byKey(const Key('appTheme-dark')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Ngôn ngữ'))).brightness, Brightness.dark);
    final prefs = c.read(localPrefsProvider);
    expect(await tester.runAsync(() async => (await prefs.get(appLanguagePref), await prefs.get(themePref))), ('vi', 'dark'));

    await tester.tap(find.byKey(const Key('appLanguage-auto')));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('giá trị đọc trước runApp: khung đầu tiên đã đúng ngôn ngữ', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), overrides: [
      initialAppearanceProvider.overrideWithValue((language: 'vi', theme: 'light')),
    ]);
    expect(find.text('Hôm nay'), findsWidgets);
  });

  testWidgets('pseudo-locale + chữ lớn ở 320dp: Tôi không vỡ bố cục', (tester) async {
    await pumpApp(tester, size: const Size(320, 640), locale: const Locale('en', 'XA'), textScale: 1.3);
    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('appTheme-dark')), 100);
    expect(tester.takeException(), isNull);
  });
}
