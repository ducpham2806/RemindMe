import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/l10n/locale_resolution.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'data/remote/remote_sync_binding.dart';
import 'data/reminder_binding.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';

/// Pseudo-locale chỉ có ở bản debug (i18n-l10n.md §8 bước 4).
const pseudoLocale = Locale('en', 'XA');

List<Locale> appSupportedLocales({bool includePseudo = kDebugMode}) => [
      for (final l in AppLocalizations.supportedLocales)
        if (includePseudo || l != pseudoLocale) l,
    ];

class RemindMeApp extends ConsumerStatefulWidget {
  const RemindMeApp({super.key, this.locale});

  /// Ngôn ngữ giao diện riêng của app (i18n-l10n.md §3); null = theo máy.
  final Locale? locale;

  @override
  ConsumerState<RemindMeApp> createState() => _RemindMeAppState();
}

class _RemindMeAppState extends ConsumerState<RemindMeApp> {
  late final GoRouter _router = buildRouter(initialLocation: ref.read(initialOnboardingDoneProvider) ? '/today' : '/welcome');

  @override
  Widget build(BuildContext context) {
    final locales = appSupportedLocales();
    final appearance = ref.watch(appearanceProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (appearance.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: widget.locale ?? (appearance.language == prefAuto ? null : Locale(appearance.language)),
      supportedLocales: locales,
      // Flutter 3.47+ tách Material/Cupertino thành package riêng: dùng delegate của material_ui/cupertino_ui,
      // không dùng danh sách sinh sẵn (vẫn trỏ tới bản cũ trong flutter_localizations).
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      localeListResolutionCallback: (preferred, supported) => resolveLocale(preferred, supported),
      routerConfig: _router,
      builder: (context, child) =>
          RemoteSyncBinding(router: _router, child: ReminderBinding(router: _router, child: child ?? const SizedBox.shrink())),
    );
  }
}
