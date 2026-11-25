import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/layout/window_size.dart';
import '../core/theme/app_icons.dart';
import '../core/theme/tokens.dart';
import '../features/quick_add/quick_add_sheet.dart';
import '../l10n/app_localizations.dart';

/// Khung điều hướng thích ứng (multi-platform.md §2 quy tắc 4): compact → thanh dưới; medium → rail; expanded → rail mở rộng.
/// Phím tắt Ctrl/Cmd+N mở Quick Add (chuẩn bị cho tablet có bàn phím và máy tính).
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.navigation});

  final StatefulNavigationShell navigation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = WindowSize.of(context);
    final items = <(AppIcons, String)>[
      (AppIcons.today, l.navToday),
      (AppIcons.calendar, l.navCalendar),
      (AppIcons.trip, l.navTrips),
      (AppIcons.user, l.navMe),
    ];
    void go(int i) => navigation.goBranch(i, initialLocation: i == navigation.currentIndex);
    final fab = FloatingActionButton(
      key: const Key('quickAddFab'),
      tooltip: l.quickAddSemantics,
      onPressed: () => showQuickAdd(context),
      child: const AppIcon(AppIcons.plus),
    );

    final Widget body;
    if (size == WindowSize.compact) {
      body = Scaffold(
        body: navigation,
        bottomNavigationBar: _BottomBar(
          key: const Key('bottomNav'),
          items: items,
          selected: navigation.currentIndex,
          onSelect: go,
          onAdd: () => showQuickAdd(context),
          addTooltip: l.quickAddSemantics,
        ),
      );
    } else {
      final extended = size == WindowSize.expanded;
      body = Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: extended,
              labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              leading: Padding(padding: const EdgeInsetsDirectional.symmetric(vertical: 8), child: fab),
              selectedIndex: navigation.currentIndex,
              onDestinationSelected: go,
              destinations: [
                for (final (icon, label) in items)
                  NavigationRailDestination(
                    icon: AppIcon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    selectedIcon: AppIcon(icon, color: Theme.of(context).colorScheme.primary),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigation),
          ],
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => showQuickAdd(context),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () => showQuickAdd(context),
      },
      child: Focus(autofocus: true, child: body),
    );
  }
}

/// Thanh dưới theo Figma (01 · Hôm nay): 2 tab · nút "+" (Quick Add) · 2 tab; tab đang chọn tô màu primary.
class _BottomBar extends StatelessWidget {
  const _BottomBar({super.key, required this.items, required this.selected, required this.onSelect, required this.onAdd, required this.addTooltip});

  final List<(AppIcons, String)> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final String addTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget tab(int i) {
      final (icon, label) = items[i];
      final on = i == selected;
      final color = on ? scheme.primary : scheme.onSurfaceVariant;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: InkWell(
            key: Key('nav-$i'),
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
            onTap: () => onSelect(i),
            child: SizedBox(
              height: 54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(icon, color: color),
                  const SizedBox(height: Tokens.space1),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, height: 1.5, color: color, fontWeight: on ? FontWeight.w600 : FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, Tokens.space3, 18, Tokens.space2),
          child: Row(
            children: [
              tab(0),
              tab(1),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space1),
                child: Tooltip(
                  message: addTooltip,
                  child: Material(
                    key: const Key('quickAddFab'),
                    color: scheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusXl)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Tokens.radiusXl),
                      onTap: onAdd,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(14),
                        child: AppIcon(AppIcons.plus, color: scheme.onPrimary, semanticLabel: addTooltip),
                      ),
                    ),
                  ),
                ),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}
