import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../archive/domain/models/archive_entry.dart';
import '../../../archive/presentation/providers/archive_providers.dart';
import '../../../import/presentation/providers/import_providers.dart';
import '../../../solve/domain/models/puzzle_metadata.dart';
import '../../../stats/presentation/providers/stats_providers.dart';

part 'home_screen.g.dart';

@riverpod
Future<List<PuzzleMetadata>> puzzleList(Ref ref) async {
  // Invalidated by the ImportNotifier after a successful import.
  final repo = ref.watch(importRepositoryProvider);
  return repo.getAllMetadata();
}

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
        title: const Text('Crosscue'),
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
                    style: const TextStyle(
                      fontFamily: CrosscueTypography.robotoMono,
                      fontSize: CrosscueTypography.timer,
                      color: CrosscueColors.onSurface2Light,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _ImportFAB(),
      body: puzzlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (puzzles) {
          if (puzzles.isEmpty) {
            return _EmptyState(
              onOpenSources: () => context.push(Routes.sourceManagement),
            );
          }

          // Use archive entries for richer status info; fall back to metadata
          final entries = archiveAsync.asData?.value ?? [];
          final entryMap = {for (final e in entries) e.puzzleId: e};

          // Sort by import date (most recent first) to pick "current" puzzle
          final sorted = List<PuzzleMetadata>.from(puzzles)
            ..sort((a, b) => b.importedAt.compareTo(a.importedAt));

          final featured = sorted.first;
          final recent = sorted.length > 1 ? sorted.sublist(1) : <PuzzleMetadata>[];

          return ListView(
            children: [
              // ── Today / Current section ──────────────────────────────
              const _SectionHeader('Current'),
              _FeaturedPuzzle(
                puzzle: featured,
                entry: entryMap[featured.id],
                onTap: () => context.push(
                    Routes.solveFor(Uri.encodeComponent(featured.id))),
              ),

              if (recent.isNotEmpty) ...[
                const Divider(height: 1),
                const _SectionHeader('Recent'),
                ...recent.map((p) {
                  final entry = entryMap[p.id];
                  return _PuzzleRow(
                    puzzle: p,
                    entry: entry,
                    onTap: () => context.push(
                        Routes.solveFor(Uri.encodeComponent(p.id))),
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

class _ImportFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(Routes.sourceManagement),
      backgroundColor: CrosscueColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrosscueSpacing.fabRadius),
      ),
      child: const Icon(Icons.add, size: 26),
    );
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CrosscueColors.onSurface3Light,
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
    final sub = [
      if (puzzle.author.isNotEmpty) puzzle.author,
      puzzle.width == puzzle.height
          ? '${puzzle.width}×${puzzle.height}'
          : '${puzzle.width}×${puzzle.height}',
    ].join(' · ');

    final elapsed = entry?.elapsedMs;
    final elapsedStr = elapsed != null && elapsed > 0
        ? '⏱ ${_formatMs(elapsed)} elapsed'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CrosscueSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            puzzle.title,
            style: const TextStyle(
              fontSize: CrosscueTypography.puzzleTitle,
              fontWeight: FontWeight.w600,
              color: CrosscueColors.onSurface1Light,
              height: 1.25,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(
                fontSize: CrosscueTypography.bodySmall,
                color: CrosscueColors.onSurface2Light,
              ),
            ),
          ],
          if (elapsedStr != null) ...[
            const SizedBox(height: 2),
            Text(
              elapsedStr,
              style: const TextStyle(
                fontSize: CrosscueTypography.bodySmall,
                color: CrosscueColors.onSurface2Light,
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
    final statusColor = _statusColor(entry);
    final statusIcon = _statusIcon(entry);
    final sub = _subtitle(entry, puzzle);

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
                        style: const TextStyle(
                          fontSize: CrosscueTypography.body,
                          fontWeight: FontWeight.w500,
                          color: CrosscueColors.onSurface1Light,
                        ),
                      ),
                      if (sub != null)
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: CrosscueTypography.label,
                            color: CrosscueColors.onSurface3Light,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: CrosscueColors.onSurface3Light,
                ),
              ],
            ),
          ),
        ),
        const Divider(
          height: 1,
          indent: 50, // 16 screenH + 20 icon + 12 gap + 2 extra = 50 per spec
          endIndent: 0,
          color: CrosscueColors.dividerLight,
        ),
      ],
    );
  }

  Color _statusColor(ArchiveEntry? e) {
    if (e == null || e.isNotStarted) return CrosscueColors.onSurface3Light;
    if (e.isCleanSolve) return CrosscueColors.primary;
    if (e.isCompleted || e.isRevealed) return CrosscueColors.correctLight;
    return CrosscueColors.primaryMid; // in progress
  }

  IconData _statusIcon(ArchiveEntry? e) {
    if (e == null || e.isNotStarted) return Icons.radio_button_unchecked;
    if (e.isCleanSolve) return Icons.star_rounded;
    if (e.isCompleted || e.isRevealed) return Icons.check_circle_outline;
    return Icons.timelapse_rounded; // in progress
  }

  String? _subtitle(ArchiveEntry? e, PuzzleMetadata p) {
    final parts = <String>[];
    if (p.author.isNotEmpty) parts.add(p.author);
    parts.add('${p.width}×${p.height}');
    return parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpenSources});
  final VoidCallback onOpenSources;

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
            'Add local puzzles from Settings to get started.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.source_outlined),
            label: const Text('Open Puzzle Sources'),
            onPressed: onOpenSources,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatMs(int ms) {
  final total = ms ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}
