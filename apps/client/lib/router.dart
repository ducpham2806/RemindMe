import 'package:go_router/go_router.dart';

import 'data/remote/account.dart';
import 'features/account/account_screens.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/import/import_screen.dart';
import 'features/items/item_detail_screen.dart';
import 'features/lists/lists_screen.dart';
import 'features/me/language_region_screen.dart';
import 'features/me/me_screen.dart';
import 'features/me/notifications_screen.dart';
import 'features/me/plan_screen.dart';
import 'features/me/privacy_screens.dart';
import 'features/onboarding/onboarding_screens.dart';
import 'features/search/search_screen.dart';
import 'features/today/today_screen.dart';
import 'features/trips/document_viewer.dart';
import 'features/trips/trips_screen.dart';
import 'shell/adaptive_shell.dart';

/// Deep link theo UX §1: `remindme://item/<id>` (= `/item/<id>`), `trip/<id>` (= `/trips/<id>`), `import/<id>` (thêm ở các sprint sau).
/// Chi tiết item, tìm kiếm và nhập từ tệp nằm ngoài shell để mở được từ mọi tab mà không đổi tab.
GoRouter buildRouter({String initialLocation = '/today'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigation) => AdaptiveShell(navigation: navigation),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/today', builder: (_, _) => const TodayScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen())]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/trips', builder: (_, _) => const TripsScreen(), routes: [
                GoRoute(
                    path: ':id',
                    builder: (_, state) => TripDetailScreen(id: state.pathParameters['id']!, initialTab: state.uri.queryParameters['tab'] ?? 'itinerary')),
              ]),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/me', builder: (_, _) => const MeScreen(), routes: [
                GoRoute(path: 'language', builder: (_, _) => const LanguageRegionScreen()),
                GoRoute(path: 'account', builder: (_, _) => const AccountScreen()),
                GoRoute(path: 'plan', builder: (_, _) => const PlanScreen()),
                GoRoute(path: 'notifications', builder: (_, _) => const NotificationsScreen()),
                GoRoute(path: 'privacy', builder: (_, _) => const PrivacyScreen(), routes: [
                  GoRoute(path: 'export', builder: (_, _) => const ExportScreen()),
                  GoRoute(path: 'delete', builder: (_, _) => const DeleteAccountScreen()),
                ]),
                GoRoute(path: 'lists', builder: (_, _) => const ListsScreen(), routes: [
                  GoRoute(path: ':id', builder: (_, state) => ListDetailScreen(id: state.pathParameters['id']!)),
                ]),
              ]),
            ]),
          ],
        ),
        GoRoute(path: '/document/:importId', builder: (_, state) => DocumentViewerScreen(importId: state.pathParameters['importId']!)),
        GoRoute(
          path: '/item/:id',
          // Mở từ thông báo: ?reminder=<id>&at=<ms UTC của lần nhắc> để hiện nút Hoãn nhắc cho đúng lần đó.
          builder: (_, state) => ItemDetailScreen(
            id: state.pathParameters['id']!,
            reminderId: state.uri.queryParameters['reminder'],
            occurrence: int.tryParse(state.uri.queryParameters['at'] ?? '') == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(int.parse(state.uri.queryParameters['at']!), isUtc: true),
          ),
        ),
        GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
        GoRoute(path: '/import', builder: (_, _) => const ImportScreen()),
        GoRoute(path: '/login', builder: (_, state) => LoginScreen(email: state.uri.queryParameters['email']), routes: [
          GoRoute(
            path: 'verify',
            builder: (_, state) => VerifyScreen(
              email: state.uri.queryParameters['email'] ?? '',
              mode: OtpMode.values.byName(state.uri.queryParameters['mode'] ?? OtpMode.signIn.name),
            ),
          ),
        ]),
        GoRoute(path: '/revoked', builder: (_, _) => const RevokedScreen()),
        GoRoute(path: '/account-deleted', builder: (_, _) => const AccountDeletedScreen()),
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        GoRoute(path: '/onboarding/goals', builder: (_, _) => const GoalsScreen()),
        GoRoute(path: '/onboarding/first', builder: (_, _) => const FirstReminderScreen()),
        GoRoute(path: '/onboarding/notify', builder: (_, _) => const NotifyPermissionScreen()),
      ],
    );
