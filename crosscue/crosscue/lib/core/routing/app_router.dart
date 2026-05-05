import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/archive/presentation/screens/archive_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/import/presentation/screens/import_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/solve/presentation/screens/solve_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../settings/settings_providers.dart';
import 'app_shell.dart';
import 'routes.dart';

part 'app_router.g.dart';

// hasSeenOnboardingProvider lives in settings_providers.dart.
// The router watches it; onboarding screen invalidates it after completion.

@riverpod
GoRouter appRouter(Ref ref) {
  final hasSeenOnboardingAsync = ref.watch(hasSeenOnboardingProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      final hasOnboarded = hasSeenOnboardingAsync.when(
        data: (v) => v,
        loading: () => false,
        error: (_, __) => false,
      );
      final onOnboarding = state.matchedLocation == Routes.onboarding;

      if (!hasOnboarded && !onOnboarding) return Routes.onboarding;
      if (hasOnboarded && onOnboarding) return Routes.home;
      return null;
    },
    routes: [
      // Full-page routes (no shell)
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.import_,
        builder: (context, state) => const ImportScreen(),
      ),
      GoRoute(
        path: Routes.solve,
        builder: (context, state) {
          final puzzleId = state.pathParameters['puzzleId']!;
          return SolveScreen(puzzleId: puzzleId);
        },
      ),

      // 4-tab shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.archive,
              builder: (context, state) => const ArchiveScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.stats,
              builder: (context, state) => const StatsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}
