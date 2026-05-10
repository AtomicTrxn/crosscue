import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _SwitchRow(
            value: _value(ref.watch(crashReportingProvider), fallback: false),
            onChanged: (_) =>
                ref.read(crashReportingProvider.notifier).toggle(),
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
        ],
      ),
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
    ref.invalidate(crosshareAutoDownloadProvider);
    ref.invalidate(crosshareLastDownloadedDateProvider);
    ref.invalidate(crosshareLastAttemptStatusProvider);

    if (context.mounted) context.go(Routes.home);
  }
}

// ---------------------------------------------------------------------------
// Local widgets (mirrors settings_screen.dart pattern)
// ---------------------------------------------------------------------------

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
