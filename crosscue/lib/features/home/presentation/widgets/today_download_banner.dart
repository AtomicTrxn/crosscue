import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline status row for the Crosshare daily auto-download, shown at the top of
/// the home list. Makes the wait honest: an in-progress fetch reads as
/// "fetching today's puzzle…" (with a spinner) rather than looking like an
/// empty library, and a failed fetch is a visibly distinct state with a retry
/// affordance. Renders nothing when [phase] is
/// [CrosshareAutoDownloadPhase.idle].
class TodayDownloadBanner extends ConsumerWidget {
  const TodayDownloadBanner({required this.phase, super.key});

  final CrosshareAutoDownloadPhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetching = phase == CrosshareAutoDownloadPhase.inProgress;
    final failed = phase == CrosshareAutoDownloadPhase.failed;
    if (!fetching && !failed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        24,
        CrosscueSpacing.screenH,
        8,
      ),
      child: Row(
        children: [
          if (fetching)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: context.crosscueOnSurface3,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fetching
                  ? "Fetching today's puzzle…"
                  : "Couldn't fetch today's puzzle",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.crosscueOnSurface2,
                  ),
            ),
          ),
          if (failed)
            TextButton(
              onPressed: () => ref
                  .read(crosshareAutoDownloadServiceProvider)
                  .attemptIfNeeded(),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
