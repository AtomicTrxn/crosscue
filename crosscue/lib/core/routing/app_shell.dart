import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'nav_icons.dart';

/// Persistent 4-tab shell. Shown for Home, Archive, Stats, and Settings tabs.
/// Full-page routes (Solve, Import, Onboarding) push over this shell.
///
/// Triggers a silent Crosshare auto-download on first build (app launch) and
/// whenever the app returns to the foreground.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger on launch — run after first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoDownload());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tryAutoDownload();
    }
  }

  Future<void> _tryAutoDownload() async {
    // Fire-and-forget — failures are recorded in settings and surfaced on the
    // Crosshare config screen; no UI feedback from the shell itself.
    await ref.read(crosshareAutoDownloadServiceProvider).attemptIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
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
    widget.navigationShell.goBranch(
      index,
      // Re-tap on the current tab scrolls to top / pops to root.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
