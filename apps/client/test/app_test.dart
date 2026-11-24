import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/app.dart';
import 'package:remindme_client/core/l10n/locale_resolution.dart';
import 'package:remindme_client/core/layout/window_size.dart';

import 'helpers.dart';

void main() {
  group('layout thích ứng (multi-platform.md §2)', () {
    testWidgets('compact: thanh điều hướng dưới', (tester) async {
      await pumpApp(tester, size: const Size(390, 844), locale: const Locale('en'));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('medium (tablet dọc): rail có nhãn', (tester) async {
      await pumpApp(tester, size: const Size(744, 1133), locale: const Locale('en'));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isFalse);
    });

    testWidgets('expanded (tablet ngang / máy tính): rail mở rộng', (tester) async {
      await pumpApp(tester, size: const Size(1280, 800), locale: const Locale('en'));
      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isTrue);
    });

    test('ngưỡng window size', () {
      expect(WindowSize.fromWidth(599), WindowSize.compact);
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(840), WindowSize.expanded);
    });
  });

  testWidgets('chuyển tab', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), locale: const Locale('en'));
    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    expect(find.text('No trips yet'), findsOneWidget);
  });

  testWidgets('tiếng Việt dùng thuật ngữ glossary', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), locale: const Locale('vi'));
    expect(find.text('Hôm nay'), findsWidgets);
    expect(find.text('Chuyến đi'), findsOneWidget);
    expect(find.text('Hôm nay chưa có việc nào'), findsOneWidget);
  });

  // Pseudo-locale dài hơn ~40% + chữ lớn 1,3x: không được tràn layout (test tự fail khi có RenderFlex overflow).
  for (final size in const [Size(320, 640), Size(744, 1133), Size(1280, 800)]) {
    testWidgets('pseudo-locale + chữ lớn không vỡ layout ở ${size.width.toInt()}dp', (tester) async {
      await pumpApp(tester, size: size, locale: pseudoLocale, textScale: 1.3);
      expect(find.textContaining('Ţöđàý'), findsWidgets);
      for (final tab in ['[Ţ', '[Çà', '[Ţŕî', '[Ṁé']) {
        final f = find.textContaining(tab).last;
        await tester.tap(f, warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('Ctrl+N mở Quick Add', (tester) async {
    await pumpApp(tester, size: const Size(1280, 800), locale: const Locale('en'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quickAddField')), findsOneWidget);
  });

  testWidgets('nút + mở Quick Add', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), locale: const Locale('en'));
    await tester.tap(find.byKey(const Key('quickAddFab')));
    await tester.pumpAndSettle();
    expect(find.text('Try “Dentist next Tue 3pm”'), findsOneWidget);
  });

  group('chuỗi fallback locale (i18n-l10n.md §3)', () {
    final supported = [const Locale('en'), const Locale('vi'), const Locale('es'), const Locale('es', '419'),
      const Locale('pt'), const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')];
    Locale r(List<Locale> p) => resolveLocale(p, supported);

    test('es-MX → es-419, es-ES → es', () {
      expect(r([const Locale('es', 'MX')]), const Locale('es', '419'));
      expect(r([const Locale('es', 'ES')]), const Locale('es'));
    });
    test('zh-HK → zh-Hant, pt-PT → pt', () {
      expect(r([const Locale('zh', 'HK')]), const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
      expect(r([const Locale('pt', 'PT')]), const Locale('pt'));
    });
    test('không hỗ trợ thì về en, không giả định tiếng Việt', () {
      expect(r([const Locale('fr', 'FR')]), const Locale('en'));
      expect(r([const Locale('fr'), const Locale('vi')]), const Locale('vi'));
      expect(r(const []), const Locale('en'));
    });
  });
}
