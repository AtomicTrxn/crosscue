import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';

const _appVersionLabel = 'v1.0.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = _value(
      ref.watch(themeModeProvider),
      fallback: ThemeMode.system,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CrosscueSpacing.screenH,
              8,
              CrosscueSpacing.screenH,
              12,
            ),
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
                  onSelectionChanged: (selection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setMode(selection.first);
                  },
                ),
              ],
            ),
          ),
          _RowDivider(),
          _SwitchRow(
            value: _value(
                  ref.watch(colorblindModeProvider),
                  fallback: ColorblindMode.none,
                ) !=
                ColorblindMode.none,
            onChanged: (_) =>
                ref.read(colorblindModeProvider.notifier).toggle(),
            leading: Icons.contrast_outlined,
            title: 'Colorblind mode',
            subtitle: 'Adds a dot to correct letters',
          ),
          const _SectionHeader('Touch & Sound'),
          _SwitchRow(
            value: _value(ref.watch(hapticsEnabledProvider), fallback: true),
            onChanged: (_) =>
                ref.read(hapticsEnabledProvider.notifier).toggle(),
            leading: Icons.vibration_outlined,
            title: 'Haptic feedback',
            subtitle: 'Vibrate on cell tap and puzzle events',
          ),
          _SwitchRow(
            value: _value(ref.watch(soundsEnabledProvider), fallback: false),
            onChanged: (_) => ref.read(soundsEnabledProvider.notifier).toggle(),
            leading: Icons.volume_up_outlined,
            title: 'Sounds',
            subtitle: 'Play subtle feedback sounds',
          ),
          _SwitchRow(
            value: _value(ref.watch(skipFilledCellsProvider), fallback: false),
            onChanged: (_) =>
                ref.read(skipFilledCellsProvider.notifier).toggle(),
            leading: Icons.skip_next_outlined,
            title: 'Skip filled cells',
            subtitle: 'Jump over filled letters while typing',
          ),
          _NavRow(
            leading: Icons.keyboard_outlined,
            title: 'Keyboard layout',
            subtitle: 'QWERTY',
            onTap: () =>
                _showStub(context, 'Keyboard layouts are not wired yet'),
          ),
          const _SectionHeader('Notifications'),
          _SwitchRow(
            value: _value(ref.watch(puzzleReminderProvider), fallback: false),
            onChanged: (_) {
              ref.read(puzzleReminderProvider.notifier).toggle();
              _showStub(context, 'Reminder scheduling is deferred');
            },
            leading: Icons.notifications_outlined,
            title: 'Puzzle reminder',
            subtitle: 'Off',
          ),
          _NavRow(
            leading: Icons.schedule_outlined,
            title: 'Puzzle reminder time',
            subtitle: '8:00 AM',
            onTap: () => _showStub(context, 'Reminder scheduling is deferred'),
          ),
          _SwitchRow(
            value: _value(ref.watch(streakReminderProvider), fallback: false),
            onChanged: (_) {
              ref.read(streakReminderProvider.notifier).toggle();
              _showStub(context, 'Streak reminders are deferred');
            },
            leading: Icons.local_fire_department_outlined,
            title: 'Streak reminder',
            subtitle: 'Off',
          ),
          _NavRow(
            leading: Icons.schedule_outlined,
            title: 'Streak reminder time',
            subtitle: '7:00 PM',
            onTap: () => _showStub(context, 'Streak reminders are deferred'),
          ),
          const _SectionHeader('Puzzles'),
          _NavRow(
            leading: Icons.source_outlined,
            title: 'Puzzle sources',
            subtitle: 'Import local files and manage sources',
            onTap: () => context.push(Routes.sourceManagement),
          ),
          const _SectionHeader('Privacy & Data'),
          _SwitchRow(
            value: _value(ref.watch(crashReportingProvider), fallback: false),
            onChanged: (_) {
              ref.read(crashReportingProvider.notifier).toggle();
            },
            leading: Icons.bug_report_outlined,
            title: 'Crash reporting',
            subtitle: 'Save a local crash log on this device',
          ),
          _NavRow(
            leading: Icons.upload_file_outlined,
            title: 'Export data',
            subtitle: 'Save a local backup',
            onTap: () => _exportData(context, ref),
          ),
          _NavRow(
            leading: Icons.download_outlined,
            title: 'Import data',
            subtitle: 'Restore from a local backup',
            onTap: () => _importData(context, ref),
          ),
          _NavRow(
            leading: Icons.delete_forever_outlined,
            title: 'Clear all data',
            subtitle: 'Delete all puzzles, progress and settings',
            trailing: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            color: Theme.of(context).colorScheme.error,
            onTap: () => _confirmClearAll(context, ref),
          ),
          const _SectionHeader('Help'),
          _NavRow(
            leading: Icons.help_outline,
            title: 'How to play',
            subtitle: 'Replay the onboarding walkthrough',
            onTap: () => context.push(Routes.onboardingReplay),
          ),
          _NavRow(
            leading: Icons.info_outline,
            title: 'About Crosscue',
            subtitle: _appVersionLabel,
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const _AboutDialog(),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final count = await ref.read(statsExportServiceProvider).exportAndShare();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported $count completed sessions')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export data: $e')),
      );
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final count = await ref.read(statsExportServiceProvider).pickAndImport();
      ref.invalidate(statsDataProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count completed sessions')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not import data: $e')),
      );
    }
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
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CrosscueColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(appDatabaseProvider);
    await db.clearAllUserData();

    ref.invalidate(hasSeenOnboardingProvider);
    ref.invalidate(themeModeProvider);
    ref.invalidate(hapticsEnabledProvider);
    ref.invalidate(colorblindModeProvider);
    ref.invalidate(soundsEnabledProvider);
    ref.invalidate(skipFilledCellsProvider);
    ref.invalidate(puzzleReminderProvider);
    ref.invalidate(streakReminderProvider);
    ref.invalidate(crashReportingProvider);

    if (context.mounted) context.go(Routes.home);
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  static const _githubUrl = 'https://github.com/AtomicTrxn/crossque';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/ic_launcher.png',
              width: 72,
              height: 72,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Crosscue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A clean, offline-first crossword app for Android',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _appVersionLabel,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: _githubUrl));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GitHub URL copied')),
                );
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text(_githubUrl),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        CrosscueSpacing.sectionTop,
        CrosscueSpacing.screenH,
        CrosscueSpacing.sectionBot,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.value,
    required this.onChanged,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          secondary: Icon(leading),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
        _RowDivider(),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.color,
  });

  final IconData leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color;
    return Column(
      children: [
        ListTile(
          leading: Icon(leading, color: effectiveColor),
          title: Text(title, style: TextStyle(color: effectiveColor)),
          subtitle: Text(subtitle),
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        _RowDivider(),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Divider(
      height: 1,
      indent: CrosscueSpacing.screenH,
      color: isLight ? CrosscueColors.dividerLight : CrosscueColors.dividerDark,
    );
  }
}

T _value<T>(AsyncValue<T> value, {required T fallback}) {
  return switch (value) {
    AsyncData(:final value) => value,
    _ => fallback,
  };
}

void _showStub(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}
