import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/choice_buttons.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

/// Tôi (UX §1 IA, Figma 27): lối tắt, tài khoản & cài đặt, ngôn ngữ & giao diện. Mục chưa làm hiện "Sắp có" và không chạm được.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final appearance = ref.watch(appearanceProvider);
    final settings = ref.read(appearanceProvider.notifier);
    const gap = SizedBox(height: Tokens.space4);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space2, Tokens.screenMargin, Tokens.space5),
          children: [
            Semantics(header: true, child: Text(l.navMe, style: theme.textTheme.headlineLarge)),
            Text(l.meSubtitle, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: Tokens.space5),
            _Group(
              radius: Tokens.radiusXl,
              dividers: true,
              rows: [
                _Row(AppIcons.inbox, l.meLists, l.meListsHint, '/me/lists', boxed: true),
                _Row(AppIcons.mail, l.meSuggestions, l.meSuggestionsHint, null, boxed: true),
                _Row(AppIcons.file, l.meImportFile, l.meImportHint, '/import', boxed: true),
              ],
            ),
            gap,
            Text(l.meAccountSettings, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            _Group(
              radius: 16,
              rows: [
                _Row(AppIcons.user, l.meAccountDevices, l.meAccountDevicesHint, null),
                _Row(AppIcons.link, l.meIntegrations, l.meIntegrationsHint, null),
                _Row(AppIcons.plus, l.mePlanUsage, l.mePlanUsageHint, null),
                _Row(AppIcons.bell, l.meNotifications, l.meNotificationsHint, null),
                _Row(AppIcons.shield, l.mePrivacy, l.mePrivacyHint, null),
                _Row(AppIcons.globe, l.meLanguageRegion, l.meLanguageRegionHint, '/me/language'),
              ],
            ),
            gap,
            Text(l.meAppearance, style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, height: 26 / 18, fontWeight: FontWeight.w600)),
            gap,
            _Choice(
              label: l.meLanguage,
              keyPrefix: 'appLanguage',
              value: appearance.language,
              options: [(prefAuto, l.meFollowDevice), ('vi', l.langNameVi), ('en', l.langNameEn)],
              onChanged: settings.setLanguage,
            ),
            gap,
            _Choice(
              label: l.meTheme,
              keyPrefix: 'appTheme',
              value: appearance.theme,
              options: [(prefAuto, l.meFollowDevice), ('light', l.meThemeLight), ('dark', l.meThemeDark)],
              onChanged: settings.setTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row {
  const _Row(this.icon, this.title, this.hint, this.route, {this.boxed = false});
  final AppIcons icon;
  final String title, hint;
  /// null = chưa làm.
  final String? route;
  /// Icon trong ô nền primaryContainer (lối tắt).
  final bool boxed;
}

class _Group extends StatelessWidget {
  const _Group({required this.rows, required this.radius, this.dividers = false});
  final List<_Row> rows;
  final double radius;
  final bool dividers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsetsDirectional.all(dividers ? 0 : Tokens.space1),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (dividers && i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
              _tile(context, rows[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, _Row r) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = r.route != null;
    final icon = AppIcon(r.icon, size: r.boxed ? (r.icon == AppIcons.mail ? 16 : 22) : 21, color: scheme.primary);
    final route = r.route;
    return InkWell(
      key: Key('me-${r.icon.name}'),
      // Màn ngoài shell (nhập từ tệp) mở chồng lên để có nút quay lại.
      onTap: route == null ? null : () => route.startsWith('/me') ? context.go(route) : context.push(route),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: r.boxed ? 66 : 0),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: r.boxed ? 14 : Tokens.space3, vertical: Tokens.space3),
            child: Row(
              children: [
                if (r.boxed)
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                    child: icon,
                  )
                else
                  icon,
                const SizedBox(width: Tokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: r.boxed
                            ? theme.textTheme.titleMedium?.copyWith(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w600)
                            : theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(enabled ? r.hint : [l.meComingSoon, r.hint].join(' · '),
                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (enabled) AppIcon(AppIcons.chevronSmall, size: 16, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ chọn 1 trong vài lựa chọn (nút ngang, mục đang chọn nền primary + dấu ✓).
class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.keyPrefix, required this.value, required this.options, required this.onChanged});
  final String label, keyPrefix, value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Tokens.space3),
          ChoiceButtons(keyPrefix: keyPrefix, value: value, options: options, onChanged: onChanged),
        ],
      ),
    );
  }
}
