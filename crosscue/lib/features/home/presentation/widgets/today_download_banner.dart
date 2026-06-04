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
  const TodayDownloadBanner({
    required this.phase,
    this.notAvailableYet = false,
    super.key,
  });

  final CrosshareAutoDownloadPhase phase;
  final bool notAvailableYet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetching = phase == CrosshareAutoDownloadPhase.inProgress;
    final failed = phase == CrosshareAutoDownloadPhase.failed;
    if (!fetching && !failed && !notAvailableYet) {
      return const SizedBox.shrink();
    }

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
          else if (notAvailableYet)
            Icon(
              Icons.schedule_outlined,
              size: 20,
              color: context.crosscueOnSurface3,
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
              _message(fetching, failed),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.crosscueOnSurface2,
                  ),
            ),
          ),
          if (failed || notAvailableYet)
            TextButton(
              onPressed: () => ref
                  .read(crosshareAutoDownloadServiceProvider)
                  .attemptIfNeeded(),
              child: Text(failed ? 'Retry' : 'Try now'),
            ),
        ],
      ),
    );
  }

  String _message(bool fetching, bool failed) {
    if (fetching) return "Fetching today's puzzle…";
    if (failed) return "Couldn't fetch today's puzzle";
    return "Today's puzzle isn't available yet";
  }
}
