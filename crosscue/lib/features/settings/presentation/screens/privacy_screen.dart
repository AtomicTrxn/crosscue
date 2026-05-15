import 'package:crosscue/core/constants/app_links.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/settings/presentation/widgets/settings_rows.dart';
import 'package:crosscue/features/stats/presentation/notifiers/stats_export_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SettingsSwitchRow(
            value: asyncSettingValue(
              ref.watch(crashReportingProvider),
              fallback: false,
            ),
            onChanged: (_) =>
                ref.read(crashReportingProvider.notifier).toggle(),
            leading: Icons.bug_report_outlined,
            title: 'Crash reporting',
            subtitle: 'Save a local crash log on this device',
          ),
          SettingsNavRow(
            leading: Icons.policy_outlined,
            title: 'Privacy policy',
            subtitle: 'View how Crosscue handles data',
            onTap: () => _openPrivacyPolicy(context),
          ),
          const _ExportRow(leading: Icons.upload_file_outlined),
          const _ImportRow(leading: Icons.download_outlined),
          SettingsNavRow(
            leading: Icons.delete_forever_outlined,
            title: 'Clear all data',
            subtitle: 'Delete all puzzles, progress and settings',
            trailing: Text(
              'Delete',
              style: TextStyle(color: context.crosscueError),
            ),
            color: context.crosscueError,
            onTap: () => _confirmClearAll(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final launched = await launchUrl(
      Uri.parse(AppLinks.privacyPolicy),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open privacy policy')),
      );
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final primary = Theme.of(ctx).colorScheme.primary;
        return AlertDialog(
          title: const Text('Clear all data?'),
          content: const Text(
            'This will permanently delete every puzzle, solve session, '
            'and setting. This cannot be undone.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ctx.crosscueError,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete everything'),
            ),
          ],
        );
      },
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
    ref.invalidate(crashReportingProvider);
    ref.invalidate(crosshareAutoDownloadProvider);
    ref.invalidate(crosshareLastDownloadedDateProvider);
    ref.invalidate(crosshareLastAttemptStatusProvider);

    if (context.mounted) context.go(Routes.home);
  }
}

// ---------------------------------------------------------------------------
// Export / Import rows — reactive wrappers around StatsExportNotifier
// ---------------------------------------------------------------------------

class _ExportRow extends ConsumerWidget {
  const _ExportRow({required this.leading});
  final IconData leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statsExportProvider);
    final busy = state is StatsExportBusy;

    // Show snackbar on terminal states.
    ref.listen(statsExportProvider, (_, next) {
      if (!context.mounted) return;
      if (next is StatsExportFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${next.message}')),
        );
        ref.read(statsExportProvider.notifier).reset();
      } else if (next is StatsExportSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export shared successfully')),
        );
        ref.read(statsExportProvider.notifier).reset();
      }
    });

    return Column(
      children: [
        ListTile(
          leading: Icon(leading),
          title: const Text('Export data'),
          subtitle: const Text('Save a local backup'),
          trailing: busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: busy
              ? null
              : () => ref.read(statsExportProvider.notifier).export(),
        ),
        const SettingsRowDivider(),
      ],
    );
  }
}

class _ImportRow extends ConsumerWidget {
  const _ImportRow({required this.leading});
  final IconData leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statsExportProvider);
    final busy = state is StatsExportBusy;

    ref.listen(statsExportProvider, (_, next) {
      if (!context.mounted) return;
      if (next is StatsExportFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${next.message}')),
        );
        ref.read(statsExportProvider.notifier).reset();
      } else if (next is StatsExportSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${next.count} sessions')),
        );
        ref.read(statsExportProvider.notifier).reset();
      }
    });

    return Column(
      children: [
        ListTile(
          leading: Icon(leading),
          title: const Text('Import data'),
          subtitle: const Text('Restore from a local backup'),
          trailing: busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: busy
              ? null
              : () => ref.read(statsExportProvider.notifier).import_(),
        ),
        const SettingsRowDivider(),
      ],
    );
  }
}
