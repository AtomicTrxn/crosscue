import 'package:crosscue/core/routing/nav_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Persistent 4-tab shell. Shown for Home, Archive, Stats, and Settings tabs.
/// Full-page routes (Solve, Import, Onboarding) push over this shell.
///
/// Crosshare auto-download is triggered by [appLifecycleObserverProvider]
/// (registered in [CrosscueApp.initState]), not from here. Keeping lifecycle
/// observation out of the shell prevents spurious downloads when the app is
/// resumed while a solve is in progress.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Branch roots that should redirect to Today instead of exiting the app.
  static const _nonTodayBranchRoots = {'/archive', '/stats', '/settings'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BackButtonListener(
      // Intercept back at the router-dispatcher level, before go_router acts.
      //
      // • Non-Today branch root (/archive, /stats, /settings): consume the
      //   event and switch to Today — never exits the app from these screens.
      // • Branch sub-pages (/settings/sources, etc.) or full-page overlays
      //   (/solve/…, /import): return false so go_router pops normally.
      // • Today (/): return false so the system handles it (app exits).
      onBackButtonPressed: () async {
        final location = GoRouterState.of(context).uri.path;
        if (_nonTodayBranchRoots.contains(location)) {
          navigationShell.goBranch(0);
          return true;
        }
        return false;
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: CrosscueNavIcon.home(selected: false),
              selectedIcon: CrosscueNavIcon.home(selected: true),
              label: 'Today',
            ),
            NavigationDestination(
              icon: CrosscueNavIcon.archive(selected: false),
              selectedIcon: CrosscueNavIcon.archive(selected: true),
              label: 'Archive',
            ),
            NavigationDestination(
              icon: CrosscueNavIcon.stats(selected: false),
              selectedIcon: CrosscueNavIcon.stats(selected: true),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: CrosscueNavIcon.settings(selected: false),
              selectedIcon: CrosscueNavIcon.settings(selected: true),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Re-tap on the current tab scrolls to top / pops to root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
