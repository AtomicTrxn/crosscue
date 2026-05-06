import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/crossword_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../import/presentation/providers/import_providers.dart';
import '../../../solve/domain/models/puzzle_metadata.dart';
import '../../../solve/presentation/notifiers/solve_notifier.dart';

part 'home_screen.g.dart';

@riverpod
Future<List<PuzzleMetadata>> puzzleList(Ref ref) async {
  final repo = ref.watch(importRepositoryProvider);
  return repo.getAllMetadata();
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzlesAsync = ref.watch(puzzleListProvider);
    final theme = CrosswordTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crosscue'),
        centerTitle: true,
        actions: [
          _ContinueButton(ref: ref, theme: theme, colorScheme: colorScheme),
        ],
      ),
      body: puzzlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (puzzles) {
          final hasInProgress = puzzles.any((p) => p.status == PuzzleStatus.inProgress);
          final hasCompleted = puzzles.any((p) => p.status == PuzzleStatus.completed || p.status == PuzzleStatus.revealed);

          return Column(
            children: [
              // Current puzzle / Continue section
              if (hasInProgress || hasCompleted)
                _ContinueSection(
                  puzzles: puzzles,
                  onTap: (p) => context.push(Routes.solveFor(Uri.encodeComponent(p.id))),
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              // Puzzle list (all puzzles)
              Expanded(
                child: puzzles.isEmpty
                    ? _EmptyState(
                        onOpenSources: () => context.push(Routes.sourceManagement),
                        theme: theme,
                        colorScheme: colorScheme,
                      )
                    : _PuzzleList(
                        puzzles: puzzles,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onOpenSources,
    required this.theme,
    required this.colorScheme,
  });

  final VoidCallback onOpenSources;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CrosscueSpacing.screenH),
      child: Column(
        children: [
          Icon(
            Icons.grid_on_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No puzzles yet',
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Import puzzles from Settings to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.source_outlined),
            label: const Text('Open Puzzle Sources'),
            onPressed: onOpenSources,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Continue section (current puzzle)
// ---------------------------------------------------------------------------

class _ContinueSection extends StatelessWidget {
  const _ContinueSection({
    required this.puzzles,
    required this.onTap,
    required this.theme,
    required this.colorScheme,
  });

  final List<PuzzleMetadata> puzzles;
  final ValueChanged<PuzzleMetadata> onTap;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final inProgress = puzzles.firstWhere(
      (p) => p.status == PuzzleStatus.inProgress,
      orElse: () => puzzles.firstWhere(
        (p) => p.status == PuzzleStatus.completed || p.status == PuzzleStatus.revealed,
        orElse: () => puzzles.first,
      ),
    );

    return Container(
      color: colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              '${inProgress.width}×${inProgress.height}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            inProgress.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            inProgress.author.isNotEmpty ? inProgress.author : 'Unknown author',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => onTap(inProgress),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Puzzle list (recent / all)
// ---------------------------------------------------------------------------

class _PuzzleList extends StatelessWidget {
  const _PuzzleList({
    required this.puzzles,
    required this.theme,
    required this.colorScheme,
  });

  final List<PuzzleMetadata> puzzles;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _SectionHeader('Current'),
        _FeaturedPuzzle(
          puzzle: puzzles.first,
          onTap: () => context.push(
              Routes.solveFor(Uri.encodeComponent(puzzles.first.id))),
        ),

        if (puzzles.length > 1) ...[
          const Divider(height: 1),
          const _SectionHeader('Recent'),
          ...puzzles.sublist(1).map((p) {
            return _PuzzleRow(
              puzzle: p,
              onTap: () => context.push(
                  Routes.solveFor(Uri.encodeComponent(p.id))),
            );
          }),
        ],

        // Bottom padding so FAB doesn't overlap last row
        const SizedBox(height: 88),
      ],
    );
  }
}

class _FeaturedPuzzle extends StatelessWidget {
  const _FeaturedPuzzle({
    required this.puzzle,
    required this.onTap,
  });

  final PuzzleMetadata puzzle;
  final ValueChanged<PuzzleMetadata> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surfaceVariant,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            '${puzzle.width}×${puzzle.height}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          puzzle.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          puzzle.author.isNotEmpty ? puzzle.author : 'Unknown author',
          style: const TextStyle(
            color: Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PuzzleRow extends StatelessWidget {
  const _PuzzleRow({
    required this.puzzle,
    required this.onTap,
  });

  final PuzzleMetadata puzzle;
  final ValueChanged<PuzzleMetadata> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surfaceVariant,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            '${puzzle.width}×${puzzle.height}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          puzzle.title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          puzzle.author.isNotEmpty ? puzzle.author : 'Unknown author',
          style: const TextStyle(
            color: Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 18,
        ),
        onTap: onTap,
      ),
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
          fontSize: CrosscueTypography.label,
          fontWeight: FontWeight.w600,
          color: CrosscueColors.onSurface3Light,
        ),
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
// Continue button (streak indicator)
// ---------------------------------------------------------------------------

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.ref,
    required this.theme,
    required this.colorScheme,
  });

  final WidgetRef ref;
  final CrosswordTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.play_arrow),
      tooltip: 'Continue',
      onPressed: () async {
        final puzzlesAsync = ref.watch(puzzleListProvider);
        final puzzles = await puzzlesAsync;
        final hasInProgress = puzzles.any((p) => p.status == PuzzleStatus.inProgress);
        final hasCompleted = puzzles.any((p) => p.status == PuzzleStatus.completed || p.status == PuzzleStatus.revealed);

        if (hasInProgress || hasCompleted) {
          final inProgress = puzzles.firstWhere(
            (p) => p.status == PuzzleStatus.inProgress,
            orElse: () => puzzles.firstWhere(
              (p) => p.status == PuzzleStatus.completed || p.status == PuzzleStatus.revealed,
              orElse: () => puzzles.first,
            ),
          );
          context.push(Routes.solveFor(Uri.encodeComponent(inProgress.id)));
        }
      },
    );
  }
}
