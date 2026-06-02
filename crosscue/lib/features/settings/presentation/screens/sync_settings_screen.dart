import 'package:crosscue/core/sync/models/sync_state.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/settings/presentation/providers/sync_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings sub-screen for cross-device sync (iCloud on iOS).
///
/// The sync engine ships (orchestrator + iCloud transport + adapters); this is
/// the opt-in / status surface for it. See issue #142.
class SyncSettingsScreen extends ConsumerWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('iCloud Sync')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vm) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CrosscueSpacing.screenH,
                20,
                CrosscueSpacing.screenH,
                4,
              ),
              child: Text(
                'Keep your puzzles, progress, and stats in sync across your '
                'devices through your private iCloud Drive. Nothing is sent to '
                'Crosscue — your data stays in your own iCloud account.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.crosscueOnSurface3,
                    ),
              ),
            ),
            const Divider(height: 32),
            SwitchListTile(
              value: vm.enabled,
              onChanged: (on) =>
                  on ? controller.enable() : controller.disable(),
              secondary: const Icon(Icons.cloud_outlined),
              title: const Text('Sync with iCloud'),
              subtitle: const Text('Sync this device with your other devices'),
            ),
            if (vm.enabled) ...[
              const Divider(height: 1),
              _StatusSection(vm: vm),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CrosscueSpacing.screenH,
                ),
                child: FilledButton.icon(
                  onPressed: _canSyncNow(vm.syncState)
                      ? () => controller.syncNow()
                      : null,
                  icon: vm.syncState is SyncRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_outlined),
                  label: Text(
                    vm.syncState is SyncRunning ? 'Syncing…' : 'Sync now',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CrosscueSpacing.screenH,
                ),
                child: TextButton(
                  onPressed: () => _confirmRemoveCloudCopy(context, controller),
                  style: TextButton.styleFrom(
                    foregroundColor: context.crosscueActionDestructive,
                  ),
                  child: const Text('Turn off and remove iCloud copy'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canSyncNow(SyncState s) => s is SyncIdle || s is SyncError;

  Future<void> _confirmRemoveCloudCopy(
    BuildContext context,
    SyncController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove iCloud copy?'),
        content: const Text(
          'This turns off sync and deletes Crosscue\'s data from iCloud. '
          'Your puzzles and progress on this device are kept.',
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.crosscueActionDestructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.disable(wipeRemote: true);
    }
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.vm});

  final SyncViewState vm;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusLine(context, vm.syncState);
    final result = vm.lastResult;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        16,
        CrosscueSpacing.screenH,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            label,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
          ),
          if (vm.account != null) ...[
            const SizedBox(height: 2),
            Text(
              'Account: ${vm.account!.displayName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.crosscueOnSurface3,
                  ),
            ),
          ],
          if (result != null && vm.syncState is SyncIdle) ...[
            const SizedBox(height: 2),
            Text(
              '${result.pushed} pushed · ${result.pulled} pulled',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.crosscueOnSurface3,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color) _statusLine(BuildContext context, SyncState s) {
    return switch (s) {
      SyncSignedOut() => (
          'iCloud unavailable — sign in to iCloud and enable iCloud Drive for '
              'Crosscue in Settings.',
          context.crosscueError,
        ),
      SyncRunning() => ('Syncing…', context.crosscueOnSurface2),
      SyncError(:final message) => (
          'Sync failed: $message',
          context.crosscueError,
        ),
      SyncIdle(:final lastSyncedAt) => (
          lastSyncedAt == null
              ? 'Connected — not synced yet'
              : 'Last synced ${_relativeTime(lastSyncedAt)}',
          context.crosscuePrimary,
        ),
      SyncDisabled() => ('Off', context.crosscueOnSurface3),
    };
  }

  static String _relativeTime(DateTime utc) {
    final diff = DateTime.now().toUtc().difference(utc);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
