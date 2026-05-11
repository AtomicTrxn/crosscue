import 'dart:math' as math;

import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/core/utils/time_format.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/presentation/providers/archive_providers.dart';
import 'package:crosscue/features/home/presentation/providers/home_providers.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_source.dart';
import 'package:crosscue/features/import/presentation/providers/source_registry_provider.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzlesAsync = ref.watch(puzzleListProvider);
    final statsAsync = ref.watch(statsDataProvider);
    final archiveAsync = ref.watch(archiveEntriesProvider);

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
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 3),
                  Text(
                    '$currentStreak',
                    style: TextStyle(
                      fontFamily: CrosscueTypography.robotoMono,
                      fontSize: CrosscueTypography.timer,
                      color: context.crosscueOnSurface2,
                      fontWeight: FontWeight.w500,
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
          if (puzzles.isEmpty) {
            return _EmptyState(
              onImport: () => context.push(Routes.import_),
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
                  return _PuzzleRow(
                    puzzle: p,
                    entry: entry,
                    onTap: () => context.push(
                      Routes.solveFor(Uri.encodeComponent(p.id)),
                    ),
                  );
                }),
              ],

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
      backgroundColor: CrosscueColors.primary,
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.crosscueOnSurface3,
          letterSpacing: 1.0,
          height: 1.2,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CrosscueSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            puzzle.title,
            style: TextStyle(
              fontSize: CrosscueTypography.puzzleTitle,
              fontWeight: FontWeight.w600,
              color: context.crosscueOnSurface1,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  sub,
                  style: TextStyle(
                    fontSize: CrosscueTypography.bodySmall,
                    color: context.crosscueOnSurface2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _PieProgress(value: completionFraction),
            ],
          ),
          // Constructor line — separate 12px #999
          if (puzzle.author.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              puzzle.author,
              style: TextStyle(
                fontSize: CrosscueTypography.label,
                color: context.crosscueOnSurface3,
              ),
            ),
          ],
          if (elapsedStr != null) ...[
            const SizedBox(height: 2),
            Text(
              elapsedStr,
              style: TextStyle(
                fontSize: CrosscueTypography.bodySmall,
                color: context.crosscueOnSurface2,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: CrosscueColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(CrosscueSpacing.buttonRadius),
              ),
              textStyle: const TextStyle(
                fontSize: CrosscueTypography.body,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
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
}

// ---------------------------------------------------------------------------
// Recent puzzle row (flat)
// ---------------------------------------------------------------------------

class _PuzzleRow extends StatelessWidget {
  const _PuzzleRow({
    required this.puzzle,
    required this.entry,
    required this.onTap,
  });

  final PuzzleMetadata puzzle;
  final ArchiveEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, entry);
    final statusIcon = _statusIcon(entry);
    final sub = _subtitle(entry, puzzle);
    final completionFraction = entry?.completionFraction ?? 0;
    final onSurface3 = context.crosscueOnSurface3;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: CrosscueSpacing.rowV,
              horizontal: CrosscueSpacing.screenH,
            ),
            child: Row(
              children: [
                // Status icon — 20dp wide
                SizedBox(
                  width: 20,
                  child: Icon(statusIcon, size: 16, color: statusColor),
                ),
                const SizedBox(width: 12),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        puzzle.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: CrosscueTypography.body,
                          fontWeight: FontWeight.w500,
                          color: context.crosscueOnSurface1,
                        ),
                      ),
                      if (sub != null)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: CrosscueTypography.label,
                                  color: onSurface3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _PieProgress(value: completionFraction),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: onSurface3,
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: 50, // 16 screenH + 20 icon + 12 gap + 2 extra = 50 per spec
          endIndent: 0,
          color: context.crosscueDivider,
        ),
      ],
    );
  }

  Color _statusColor(BuildContext context, ArchiveEntry? e) {
    if (e == null || e.isNotStarted) return context.crosscueOnSurface3;
    if (e.isCleanSolve) return CrosscueColors.primary;
    if (e.isCompleted || e.isRevealed) return context.crosscueCorrect;
    return CrosscueColors.primaryMid; // in progress
  }

  IconData _statusIcon(ArchiveEntry? e) {
    if (e == null || e.isNotStarted) return Icons.radio_button_unchecked;
    if (e.isCleanSolve) return Icons.star_rounded;
    if (e.isCompleted || e.isRevealed) return Icons.check_circle_outline;
    return Icons.timelapse_rounded; // in progress
  }

  String? _subtitle(ArchiveEntry? e, PuzzleMetadata p) {
    final parts = <String>['${p.width}×${p.height}'];
    if (p.difficulty != null && p.difficulty!.isNotEmpty) {
      parts.add(p.difficulty!);
    }
    if (p.author.isNotEmpty) parts.add(p.author);
    return parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _PieProgress extends StatelessWidget {
  const _PieProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _PieProgressPainter(
          value: value.clamp(0.0, 1.0),
          fill: CrosscueColors.primary,
          track: CrosscueColors.trackGrey,
        ),
      ),
    );
  }
}

class _PieProgressPainter extends CustomPainter {
  const _PieProgressPainter({
    required this.value,
    required this.fill,
    required this.track,
  });

  final double value;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = track;
    canvas.drawCircle(center, radius - 1.25, trackPaint);

    if (value <= 0) return;
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fill;
    if (value >= 1) {
      canvas.drawCircle(center, radius - 1.25, fillPaint);
      return;
    }

    final rect = Rect.fromCircle(center: center, radius: radius - 1.25);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -math.pi / 2, math.pi * 2 * value, false)
      ..close();
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(_PieProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.fill != fill ||
        oldDelegate.track != track;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImport});
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_on_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No puzzles yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Import a local puzzle to get started.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.source_outlined),
            label: const Text('Import Puzzle'),
            onPressed: onImport,
          ),
        ],
      ),
    );
  }
}
