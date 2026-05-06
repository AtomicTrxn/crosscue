import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nav_icons.dart';

/// Persistent 4-tab shell. Shown for Home, Archive, Stats, and Settings tabs.
/// Full-page routes (Solve, Import, Onboarding) push over this shell.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
