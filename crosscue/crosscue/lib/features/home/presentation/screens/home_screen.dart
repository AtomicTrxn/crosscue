import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/routing/routes.dart';
import '../../../import/presentation/providers/import_providers.dart';
import '../../../solve/domain/models/puzzle_metadata.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Crosscue')),
      body: puzzlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (puzzles) => puzzles.isEmpty
            ? _EmptyState(
                onOpenSources: () => context.push(Routes.sourceManagement),
              )
            : _PuzzleList(puzzles: puzzles),
      ),
    );
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
// Puzzle list
// ---------------------------------------------------------------------------

class _PuzzleList extends ConsumerWidget {
  const _PuzzleList({required this.puzzles});
  final List<PuzzleMetadata> puzzles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: puzzles.length,
      itemBuilder: (context, index) {
        final puzzle = puzzles[index];
        return _PuzzleTile(puzzle: puzzle);
      },
    );
  }
}

class _PuzzleTile extends StatelessWidget {
  const _PuzzleTile({required this.puzzle});
  final PuzzleMetadata puzzle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          '${puzzle.width}×${puzzle.height}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
      ),
      title: Text(
        puzzle.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        puzzle.author.isNotEmpty ? puzzle.author : 'Unknown author',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          context.push(Routes.solveFor(Uri.encodeComponent(puzzle.id))),
    );
  }
}
