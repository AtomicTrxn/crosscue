import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/core/utils/time_format.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/presentation/providers/archive_providers.dart';
import 'package:crosscue/features/archive/presentation/widgets/puzzle_list_tile.dart';
import 'package:crosscue/features/home/presentation/providers/home_providers.dart';
import 'package:crosscue/features/home/presentation/widgets/past_puzzles_section.dart';
import 'package:crosscue/features/home/presentation/widgets/today_download_banner.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_source.dart';
import 'package:crosscue/features/import/presentation/providers/source_registry_provider.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _streakEmojiStyle = TextStyle(fontSize: 16);
const _streakCountStyle = TextStyle(
  fontFamily: CrosscueTypography.robotoMono,
  fontSize: CrosscueTypography.timer,
  fontWeight: FontWeight.w500,
);
const _sectionHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.0,
  height: 1.2,
);
const _featuredTitleStyle = TextStyle(
  fontSize: CrosscueTypography.puzzleTitle,
  fontWeight: FontWeight.w600,
  height: 1.25,
);
const _featuredSubtitleStyle = TextStyle(
  fontSize: CrosscueTypography.bodySmall,
);
const _featuredAuthorStyle = TextStyle(fontSize: CrosscueTypography.label);
const _primaryButtonTextStyle = TextStyle(
  fontSize: CrosscueTypography.body,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.4,
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzlesAsync = ref.watch(puzzleListProvider);
    final statsAsync = ref.watch(statsDataProvider);
    final archiveAsync = ref.watch(archiveEntriesProvider);
    final autoDownloadPhase = ref.watch(crosshareAutoDownloadProgressProvider);
    final crosshareAutoEnabled = ref.watch(crosshareAutoDownloadProvider);
    final lastCrosshareStatus = ref.watch(
      crosshareLastAttemptStatusProvider,
    );

    final currentStreak = statsAsync.when(
      data: (s) => s.currentStreak,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          // Streak indicator
          if (currentStreak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: _streakEmojiStyle),
                  const SizedBox(width: 3),
                  Text(
                    '$currentStreak',
                    style: _streakCountStyle.copyWith(
                      color: context.crosscueOnSurface2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: const _ImportFAB(),
      body: puzzlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (puzzles) {
          final notAvailableYet = crosshareAutoEnabled &&
              autoDownloadPhase == CrosshareAutoDownloadPhase.idle &&
              lastCrosshareStatus.asData?.value == CrosshareStatus.notFound;
          final showDownloadBanner =
              autoDownloadPhase != CrosshareAutoDownloadPhase.idle ||
                  notAvailableYet;

          if (puzzles.isEmpty) {
            return ListView(
              children: [
                // A pending/failed daily download is an honest stand-in for the
                // generic "no puzzles yet" empty state.
                if (showDownloadBanner)
                  TodayDownloadBanner(
                    phase: autoDownloadPhase,
                    notAvailableYet: notAvailableYet,
                  )
                else
                  const _EmptyState(),
                const PastPuzzlesSection(),
                const SizedBox(height: 88),
              ],
            );
          }

          // Use archive entries for richer status info; fall back to metadata
          final entries = archiveAsync.asData?.value ?? [];
          final entryMap = {for (final e in entries) e.puzzleId: e};

          // Sort by import date (most recent first) to pick "current" puzzle
          final sorted = List<PuzzleMetadata>.from(puzzles)
            ..sort((a, b) => b.importedAt.compareTo(a.importedAt));

          final featured = sorted.first;
          final recent =
              sorted.length > 1 ? sorted.sublist(1) : <PuzzleMetadata>[];

          return ListView(
            children: [
              // Today's daily is still fetching (or failed) while an earlier
              // puzzle is featured — surface that above the content.
              if (showDownloadBanner)
                TodayDownloadBanner(
                  phase: autoDownloadPhase,
                  notAvailableYet: notAvailableYet,
                ),
              const SizedBox(height: 20),
              _FeaturedPuzzle(
                puzzle: featured,
                entry: entryMap[featured.id],
                onTap: () => context.push(
                  Routes.solveFor(Uri.encodeComponent(featured.id)),
                ),
              ),

              if (recent.isNotEmpty) ...[
                Divider(height: 1, color: context.crosscueDivider),
                const _SectionHeader('Recent'),
                ...recent.map((p) {
                  final entry = entryMap[p.id];
                  return PuzzleListTile(
                    title: p.title,
                    entry: entry,
                    subtitle: _recentSubtitle(p),
                    showProgress: true,
                    onTap: () => context.push(
                      Routes.solveFor(Uri.encodeComponent(p.id)),
                    ),
                  );
                }),
              ],

              const PastPuzzlesSection(),

              // Bottom padding so FAB doesn't overlap last row
              const SizedBox(height: 88),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FAB — navigate to puzzle sources / import
// ---------------------------------------------------------------------------

class _ImportFAB extends ConsumerWidget {
  const _ImportFAB();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledSources = ref.watch(sourceRegistryProvider).enabledSources;
    final hasDownloadSource = enabledSources.any(_hasDownloader);

    return FloatingActionButton(
      onPressed: () {
        if (hasDownloadSource) {
          context.push(Routes.sourceManagement);
        } else {
          context.push(Routes.import_);
        }
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrosscueSpacing.fabRadius),
      ),
      child: const Icon(Icons.add, size: 26),
    );
  }

  bool _hasDownloader(PuzzleSource source) {
    // Any enabled, legally-cleared non-local source can provide downloads.
    return source.licenseStatus != LicenseStatus.userImport;
  }
}

// ---------------------------------------------------------------------------
// Section header
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

// ---------------------------------------------------------------------------
// Featured puzzle block (current / top of list)
// ---------------------------------------------------------------------------

class _FeaturedPuzzle extends StatelessWidget {
  const _FeaturedPuzzle({
    required this.puzzle,
    required this.entry,
    required this.onTap,
  });

  final PuzzleMetadata puzzle;
  final ArchiveEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _ctaLabel(entry);
    // Subtitle: size (+ difficulty if present)
    final sizeParts = ['${puzzle.width}×${puzzle.height}'];
    if (puzzle.difficulty != null && puzzle.difficulty!.isNotEmpty) {
      sizeParts.add(puzzle.difficulty!);
    }
    final sub = sizeParts.join(' · ');
    final completionFraction = entry?.completionFraction ?? 0;

    final elapsed = entry?.elapsedMs;
    final elapsedStr = elapsed != null && elapsed > 0
        ? '⏱ ${formatMs(elapsed)} elapsed'
        : null;
    final dateStr = _formatPublishDate(puzzle.publishDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CrosscueSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dateStr != null) ...[
            Text(
              dateStr,
              style: _featuredSubtitleStyle.copyWith(
                color: context.crosscueOnSurface2,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            puzzle.title,
            style: _featuredTitleStyle.copyWith(
              color: context.crosscueOnSurface1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  sub,
                  style: _featuredSubtitleStyle.copyWith(
                    color: context.crosscueOnSurface2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PuzzleProgressPie(value: completionFraction),
            ],
          ),
          // Constructor line — separate 12px #999
          if (puzzle.author.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              puzzle.author,
              style: _featuredAuthorStyle.copyWith(
                color: context.crosscueOnSurface3,
              ),
            ),
          ],
          if (elapsedStr != null) ...[
            const SizedBox(height: 2),
            Text(
              elapsedStr,
              style: _featuredSubtitleStyle.copyWith(
                color: context.crosscueOnSurface2,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(CrosscueSpacing.buttonRadius),
              ),
              textStyle: _primaryButtonTextStyle,
            ),
            child: Text(status),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _ctaLabel(ArchiveEntry? e) {
    if (e == null || e.isNotStarted) return 'SOLVE';
    if (e.isCompleted || e.isRevealed) return 'REVIEW';
    return 'CONTINUE SOLVING';
  }

  String? _formatPublishDate(DateTime? d) {
    if (d == null) return null;
    return formatPuzzlePublishDateShort(d);
  }
}

String _recentSubtitle(PuzzleMetadata p) {
  final parts = <String>['${p.width}×${p.height}'];
  if (p.difficulty != null && p.difficulty!.isNotEmpty) {
    parts.add(p.difficulty!);
  }
  if (p.author.isNotEmpty) parts.add(p.author);
  return parts.join(' · ');
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CrosscueSpacing.screenH,
        vertical: 48,
      ),
      child: Column(
        children: [
          Icon(
            Icons.grid_on_outlined,
            size: 72,
            color: context.crosscueOnSurface3,
          ),
          const SizedBox(height: 16),
          Text(
            'No puzzles yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a past puzzle below, or tap + to import your own.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.crosscueOnSurface3,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
