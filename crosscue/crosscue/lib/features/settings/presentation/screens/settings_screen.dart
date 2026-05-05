import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/settings/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final hapticsAsync = ref.watch(hapticsEnabledProvider);

    final themeMode = themeModeAsync.when(
      data: (m) => m,
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
    );
    final hapticsEnabled = hapticsAsync.when(
      data: (v) => v,
      loading: () => true,
      error: (_, __) => true,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          const _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setMode(selection.first);
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // ── Feedback ────────────────────────────────────────────────────
          const _SectionHeader('Feedback'),
          SwitchListTile(
            value: hapticsEnabled,
            onChanged: (_) =>
                ref.read(hapticsEnabledProvider.notifier).toggle(),
            title: const Text('Haptic feedback'),
            subtitle: const Text('Vibrate on cell tap and puzzle events'),
          ),
          const Divider(),

          // ── Puzzles ─────────────────────────────────────────────────────
          const _SectionHeader('Puzzles'),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Import local puzzle'),
            subtitle:
                const Text('Choose a .puz or .ipuz file from this device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.import_),
          ),
          ListTile(
            leading: const Icon(Icons.source_outlined),
            title: const Text('Puzzle sources'),
            subtitle: const Text('Manage local import and future sources'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.sourceManagement),
          ),
          const Divider(),

          // ── Data ────────────────────────────────────────────────────────
          const _SectionHeader('Data'),
          ListTile(
            leading:
                const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text('Clear all data',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('Delete all puzzles, progress and settings'),
            onTap: () => _confirmClearAll(context, ref),
          ),
          const Divider(),

          // ── About ───────────────────────────────────────────────────────
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Crosscue'),
            subtitle: Text('v0.1.0-sprint6'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will permanently delete every puzzle, solve session, '
          'and setting. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Delete all puzzles (cascades to clues, sessions, cell_progress) and all
    // settings rows. Sources seed row is preserved by cascade direction.
    final db = ref.read(appDatabaseProvider);
    await db.clearAllUserData();

    // Invalidate cached settings so the router re-reads has_seen_onboarding
    // (now false) and redirects to onboarding on the next build.
    ref.invalidate(hasSeenOnboardingProvider);
    ref.invalidate(themeModeProvider);
    ref.invalidate(hapticsEnabledProvider);

    if (context.mounted) context.go(Routes.home);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
