import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/layout/window_size.dart';
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
    final items = <(IconData, IconData, String)>[
      (Icons.wb_sunny_outlined, Icons.wb_sunny, l.navToday),
      (Icons.calendar_month_outlined, Icons.calendar_month, l.navCalendar),
      (Icons.luggage_outlined, Icons.luggage, l.navTrips),
      (Icons.person_outline, Icons.person, l.navMe),
    ];
    void go(int i) => navigation.goBranch(i, initialLocation: i == navigation.currentIndex);
    final fab = FloatingActionButton(
      key: const Key('quickAddFab'),
      tooltip: l.quickAddSemantics,
      onPressed: () => showQuickAdd(context),
      child: const Icon(Icons.add),
    );

    final Widget body;
    if (size == WindowSize.compact) {
      body = Scaffold(
        body: navigation,
        floatingActionButton: fab,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigation.currentIndex,
          onDestinationSelected: go,
          destinations: [
            for (final (icon, selected, label) in items)
              NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
          ],
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
                for (final (icon, selected, label) in items)
                  NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
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
