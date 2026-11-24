import 'package:material_ui/material_ui.dart';

/// Chọn locale hỗ trợ gần nhất theo chuỗi fallback ở i18n-l10n.md §3:
/// `pt-PT → pt → en`, `zh-HK → zh-Hant → en`, `es-MX → es-419 → es → en`. Không bao giờ giả định tiếng Việt.
Locale resolveLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  final sup = supported.toList();
  Locale? find(String lang, {String? script, String? country}) {
    for (final s in sup) {
      if (s.languageCode == lang && s.scriptCode == script && s.countryCode == country) return s;
    }
    return null;
  }

  for (final p in preferred ?? const <Locale>[]) {
    final lang = p.languageCode;
    final script = p.scriptCode ?? (lang == 'zh' && const {'HK', 'TW', 'MO'}.contains(p.countryCode) ? 'Hant' : null);
    final candidates = <Locale?>[
      find(lang, script: p.scriptCode, country: p.countryCode),
      if (script != null) find(lang, script: script),
      if (lang == 'es' && p.countryCode != null && p.countryCode != 'ES') find(lang, country: '419'),
      find(lang),
    ];
    for (final c in candidates) {
      if (c != null) return c;
    }
  }
  return find('en') ?? sup.first;
}
