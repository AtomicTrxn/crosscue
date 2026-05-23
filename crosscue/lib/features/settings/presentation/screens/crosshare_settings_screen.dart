import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/import/presentation/notifiers/crosshare_notifier.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CrosshareSettingsScreen extends ConsumerWidget {
  const CrosshareSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoEnabled = ref.watch(crosshareAutoDownloadProvider);
    final dlState = ref.watch(crosshareProvider);
    final lastStatus = ref.watch(crosshareLastAttemptStatusProvider);
    final isDownloading = dlState is CrosshareDownloading;

    // Pop back after a successful manual download.
    ref.listen<CrosshareState>(crosshareProvider, (_, next) {
      if (next is CrosshareSuccess && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: ${next.title}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Crosshare Daily Mini')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Attribution card
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CrosscueSpacing.screenH,
              20,
              CrosscueSpacing.screenH,
              4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Crosshare',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Crosshare is a free, community-run platform for sharing '
                  'and solving crossword puzzles. Daily mini crosswords are '
                  'published by the community every day.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.crosscueOnSurface3,
                      ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openCrosshare(context),
                  icon: const Icon(Icons.open_in_browser_outlined, size: 18),
                  label: const Text('Visit crosshare.org'),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // Auto-download toggle
          SwitchListTile(
            value: autoEnabled,
            onChanged: (_) =>
                ref.read(crosshareAutoDownloadProvider.notifier).toggle(),
            secondary: const Icon(Icons.download_for_offline_outlined),
            title: const Text('Auto-download daily mini'),
            subtitle: const Text(
              'Fetch today\'s puzzle automatically on launch and when returning to the app',
            ),
            isThreeLine: true,
          ),

          const Divider(height: 1),

          // Last attempt status (shown when auto-download is on)
          if (autoEnabled) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CrosscueSpacing.screenH,
                16,
                CrosscueSpacing.screenH,
                4,
              ),
              child: Text(
                'Last attempt',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            lastStatus.when(
              data: (status) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  CrosscueSpacing.screenH,
                  4,
                  CrosscueSpacing.screenH,
                  16,
                ),
                child: Text(
                  _statusLabel(status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _statusColor(context, status),
                      ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],

          // Error from manual download
          if (dlState is CrosshareFailure) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CrosscueSpacing.screenH,
                vertical: 8,
              ),
              child: Text(
                dlState.message,
                style: TextStyle(color: context.crosscueError, fontSize: 13),
              ),
            ),
          ],
          if (dlState is CrosshareDuplicate) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CrosscueSpacing.screenH,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's puzzle is already in your library.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.go(Routes.home),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Open today'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 32),

          // Manual download button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CrosscueSpacing.screenH,
            ),
            child: FilledButton.icon(
              onPressed: isDownloading
                  ? null
                  : () => ref.read(crosshareProvider.notifier).download(),
              icon: isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              label:
                  Text(isDownloading ? 'Downloading…' : 'Get today\'s puzzle'),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'success' => 'Downloaded successfully',
      'duplicate' => 'Already in library',
      'not_found' => "Today's puzzle not available yet",
      'network_error' => 'Network error — check your connection',
      _ => 'No download attempted yet',
    };
  }

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'success' || 'duplicate' => context.crosscuePrimary,
      'not_found' || 'network_error' => context.crosscueError,
      _ => context.crosscueOnSurface3,
    };
  }

  Future<void> _openCrosshare(BuildContext context) async {
    final uri = Uri.parse('https://crosshare.org');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open crosshare.org')),
        );
      }
    }
  }
}
