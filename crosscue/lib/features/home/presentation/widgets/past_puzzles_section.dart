import 'dart:async';

import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/home/domain/models/past_puzzle_item.dart';
import 'package:crosscue/features/home/presentation/notifiers/past_puzzles_notifier.dart';
import 'package:crosscue/features/home/presentation/notifiers/past_puzzles_state.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _sectionHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.0,
  height: 1.2,
);
const _rowTitleStyle = TextStyle(
  fontSize: CrosscueTypography.body,
  fontWeight: FontWeight.w500,
);
const _rowDateStyle = TextStyle(
  fontSize: CrosscueTypography.label,
  fontWeight: FontWeight.w500,
);
const _rowAuthorStyle = TextStyle(fontSize: CrosscueTypography.label);

/// The "Past puzzles" section rendered below today's puzzle on the Today
/// screen. Lists Crosshare archive entries with download / solve actions and
/// supports infinite scroll backward via [PastPuzzlesNotifier.loadMore].
class PastPuzzlesSection extends ConsumerWidget {
  const PastPuzzlesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(crosshareAutoDownloadProvider)) {
      return const SizedBox.shrink();
    }

    final async = ref.watch(pastPuzzlesProvider);

    return async.when(
      loading: () => const _LoadingHeader(),
      error: (e, _) => _ErrorHeader(
        message: e.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(pastPuzzlesProvider),
      ),
      data: (state) {
        if (state.items.isEmpty && !state.hasMore) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader('Past puzzles'),
            for (final item in state.items)
              _PastPuzzleRow(
                item: item,
                isDownloading: state.downloadingIds.contains(item.entry.id),
                error: state.downloadErrors[item.entry.id],
              ),
            _FooterControls(state: state),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Header / loading / error
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        20,
        CrosscueSpacing.screenH,
        CrosscueSpacing.sectionBot,
      ),
      child: Text(
        label.toUpperCase(),
        style: _sectionHeaderStyle.copyWith(
          color: context.crosscueOnSurface3,
        ),
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: CrosscueSpacing.screenH,
        vertical: 24,
      ),
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorHeader extends StatelessWidget {
  const _ErrorHeader({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CrosscueSpacing.screenH,
        vertical: 24,
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.crosscueOnSurface3),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer: load-more / end-of-archive / mid-stream error
// ---------------------------------------------------------------------------

class _FooterControls extends ConsumerWidget {
  const _FooterControls({required this.state});
  final PastPuzzlesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CrosscueSpacing.screenH,
          vertical: 16,
        ),
        child: Column(
          children: [
            Text(
              state.loadMoreError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.crosscueOnSurface3),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(pastPuzzlesProvider.notifier).retryLoadMore(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          CrosscueSpacing.screenH,
          16,
          CrosscueSpacing.screenH,
          24,
        ),
        child: Text(
          'No earlier puzzles available.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: CrosscueTypography.label,
            color: context.crosscueOnSurface3,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CrosscueSpacing.screenH,
        vertical: 12,
      ),
      child: TextButton(
        onPressed: state.isLoadingMore
            ? null
            : () => ref.read(pastPuzzlesProvider.notifier).loadMore(),
        child: state.isLoadingMore
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Load more'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single row
// ---------------------------------------------------------------------------

class _PastPuzzleRow extends ConsumerWidget {
  const _PastPuzzleRow({
    required this.item,
    required this.isDownloading,
    required this.error,
  });

  final PastPuzzleItem item;
  final bool isDownloading;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface2 = context.crosscueOnSurface2;
    final onSurface3 = context.crosscueOnSurface3;
    final divider = context.crosscueDivider;

    return Column(
      children: [
        InkWell(
          onTap: isDownloading ? null : () => _onTap(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CrosscueSpacing.screenH,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(item.entry.date),
                        style: _rowDateStyle.copyWith(color: onSurface2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.entry.title,
                        style: _rowTitleStyle.copyWith(
                          color: context.crosscueOnSurface1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.entry.authorName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.entry.authorName,
                          style: _rowAuthorStyle.copyWith(color: onSurface3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          error!,
                          style: _rowAuthorStyle.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _TrailingAction(
                  isImported: item.isImported,
                  isDownloading: isDownloading,
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: CrosscueSpacing.screenH,
          endIndent: CrosscueSpacing.screenH,
          color: divider,
        ),
      ],
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    if (item.isImported) {
      unawaited(
        context.push(Routes.solveFor(Uri.encodeComponent(item.localPuzzleId!))),
      );
      return;
    }
    final notifier = ref.read(pastPuzzlesProvider.notifier);
    final puzzleId = await notifier.download(item.entry);
    if (puzzleId != null && context.mounted) {
      unawaited(
        context.push(Routes.solveFor(Uri.encodeComponent(puzzleId))),
      );
    }
  }

  String _formatDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[d.weekday - 1]} ${months[d.month - 1]} ${d.day}';
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.isImported,
    required this.isDownloading,
  });

  final bool isImported;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    if (isDownloading) {
      return const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(
      isImported ? Icons.chevron_right : Icons.download_outlined,
      color: context.crosscueOnSurface3,
      size: 22,
    );
  }
}
