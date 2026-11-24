import 'package:go_router/go_router.dart';

import 'features/calendar/calendar_screen.dart';
import 'features/import/import_screen.dart';
import 'features/items/item_detail_screen.dart';
import 'features/lists/lists_screen.dart';
import 'features/me/me_screen.dart';
import 'features/search/search_screen.dart';
import 'features/today/today_screen.dart';
import 'features/trips/trips_screen.dart';
import 'shell/adaptive_shell.dart';

/// Deep link theo UX §1: `remindme://item/<id>` (= `/item/<id>`), `trip/<id>`, `import/<id>` (thêm ở các sprint sau).
/// Chi tiết item, tìm kiếm và nhập từ tệp nằm ngoài shell để mở được từ mọi tab mà không đổi tab.
GoRouter buildRouter() => GoRouter(
      initialLocation: '/today',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigation) => AdaptiveShell(navigation: navigation),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/today', builder: (_, _) => const TodayScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/trips', builder: (_, _) => const TripsScreen())]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/me', builder: (_, _) => const MeScreen(), routes: [
                GoRoute(path: 'lists', builder: (_, _) => const ListsScreen(), routes: [
                  GoRoute(path: ':id', builder: (_, state) => ListDetailScreen(id: state.pathParameters['id']!)),
                ]),
              ]),
            ]),
          ],
        ),
        GoRoute(path: '/item/:id', builder: (_, state) => ItemDetailScreen(id: state.pathParameters['id']!)),
        GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
        GoRoute(path: '/import', builder: (_, _) => const ImportScreen()),
      ],
    );
