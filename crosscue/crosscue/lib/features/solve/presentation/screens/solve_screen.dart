import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/enums.dart';
import '../notifiers/solve_notifier.dart';
import '../widgets/clue_panel.dart';
import '../widgets/crossword_grid.dart';

class SolveScreen extends ConsumerWidget {
  const SolveScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solveAsync = ref.watch(solveProvider(puzzleId));

    return solveAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load puzzle:\n$e'),
          ),
        ),
      ),
      data: (solveState) {
        final puzzle = solveState.puzzle;
        final isComplete = solveState.status == PuzzleStatus.solved ||
            solveState.status == PuzzleStatus.solvedWithHelp;

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.pop()),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  puzzle.metadata.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (puzzle.metadata.author.isNotEmpty)
                  Text(
                    puzzle.metadata.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            actions: [
              // Timer display
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: _TimerDisplay(seconds: solveState.elapsedSeconds),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Completion banner
              if (isComplete)
                MaterialBanner(
                  content: Text(
                    solveState.status == PuzzleStatus.solved
                        ? '🎉 Solved!'
                        : '✅ Completed with help!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),

              // Grid — takes remaining space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: CrosswordGrid(
                    puzzleId: puzzleId,
                    solveState: solveState,
                  ),
                ),
              ),

              // Clue panel at bottom
              CluePanel(solveState: solveState),

              // Bottom safe area
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}

/// Formats elapsed seconds as MM:SS.
class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final text =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontFamily: 'RobotoMono',
          ),
    );
  }
}
