import 'package:go_router/go_router.dart';

import 'features/calendar/calendar_screen.dart';
import 'features/me/me_screen.dart';
import 'features/today/today_screen.dart';
import 'features/trips/trips_screen.dart';
import 'shell/adaptive_shell.dart';

/// Deep link theo UX §1: `remindme://item/<id>`, `trip/<id>`, `import/<id>` (thêm route ở các sprint sau).
GoRouter buildRouter() => GoRouter(
      initialLocation: '/today',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigation) => AdaptiveShell(navigation: navigation),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/today', builder: (_, _) => const TodayScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/trips', builder: (_, _) => const TripsScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/me', builder: (_, _) => const MeScreen())]),
          ],
        ),
      ],
    );
