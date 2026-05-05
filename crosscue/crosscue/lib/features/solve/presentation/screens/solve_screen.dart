import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/settings/settings_providers.dart';
import '../../domain/models/enums.dart';
import '../notifiers/solve_notifier.dart';
import '../notifiers/solve_state.dart';
import '../widgets/clue_panel.dart';
import '../widgets/crossword_grid.dart';

class SolveScreen extends ConsumerStatefulWidget {
  const SolveScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen>
    with WidgetsBindingObserver {
  bool _completionSheetShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-pause when app goes to background; auto-resume is handled by the
  /// overlay tap (see [_PauseOverlay]) per topic-17 §4.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.hidden) {
      ref.read(solveProvider(widget.puzzleId).notifier).pause();
    }
  }

  bool get _hapticsOn {
    final async = ref.read(hapticsEnabledProvider);
    return async.when(data: (v) => v, loading: () => true, error: (_, __) => true);
  }

  void _maybeShowCompletionSheet(SolveState solveState) {
    final isComplete = solveState.status == PuzzleStatus.solved ||
        solveState.status == PuzzleStatus.solvedWithHelp ||
        solveState.status == PuzzleStatus.revealed;
    if (!isComplete || _completionSheetShown) return;

    _completionSheetShown = true;

    if (_hapticsOn) {
      HapticFeedback.heavyImpact();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        builder: (ctx) => _CompletionSheet(
          solveState: solveState,
          onDone: () {
            Navigator.of(ctx).pop();
            if (mounted) context.pop();
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final solveAsync = ref.watch(solveProvider(widget.puzzleId));

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
        _maybeShowCompletionSheet(solveState);

        final puzzle = solveState.puzzle;
        final isComplete = solveState.status == PuzzleStatus.solved ||
            solveState.status == PuzzleStatus.solvedWithHelp ||
            solveState.status == PuzzleStatus.revealed;

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
              // Timer — tap to pause/resume (topic-17 §4)
              GestureDetector(
                onTap: () {
                  final notifier =
                      ref.read(solveProvider(widget.puzzleId).notifier);
                  if (solveState.isPaused) {
                    notifier.resume();
                  } else {
                    notifier.pause();
                  }
                },
                child: Center(
                  child: _TimerDisplay(
                    seconds: solveState.elapsedSeconds,
                    isPaused: solveState.isPaused,
                  ),
                ),
              ),
              // Check / Reveal overflow menu (topic-11)
              if (!isComplete)
                _CheckRevealMenu(puzzleId: widget.puzzleId),
              const SizedBox(width: 4),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Grid — takes remaining space
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: CrosswordGrid(
                        puzzleId: widget.puzzleId,
                        solveState: solveState,
                      ),
                    ),
                  ),

                  // Clue panel at bottom
                  CluePanel(solveState: solveState),

                  // Bottom safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),

              // Pause overlay — shown when paused and puzzle not yet complete
              if (solveState.isPaused && !isComplete)
                _PauseOverlay(
                  onResume: () => ref
                      .read(solveProvider(widget.puzzleId).notifier)
                      .resume(),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Completion bottom sheet (topic-17 §2)
// ---------------------------------------------------------------------------

class _CompletionSheet extends StatelessWidget {
  const _CompletionSheet({
    required this.solveState,
    required this.onDone,
  });

  final SolveState solveState;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final status = solveState.status;
    final isClean = status == PuzzleStatus.solved;
    final isRevealed = status == PuzzleStatus.revealed;

    final (emoji, headline, subline) = switch (status) {
      PuzzleStatus.solved => (
          '🎉',
          'Puzzle solved!',
          'Clean solve — no hints used.'
        ),
      PuzzleStatus.solvedWithHelp => (
          '✅',
          'Completed!',
          'Solved with checks or reveals.'
        ),
      PuzzleStatus.revealed => (
          '👁️',
          'Puzzle revealed',
          'Full puzzle was revealed.'
        ),
      _ => ('✅', 'Done!', ''),
    };

    final m = solveState.elapsedSeconds ~/ 60;
    final s = solveState.elapsedSeconds % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (ctx, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Emoji + headline
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                headline,
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subline.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subline,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],

              const SizedBox(height: 24),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: 'Time',
                    value: timeStr,
                  ),
                  if (!isRevealed)
                    _StatChip(
                      icon: isClean
                          ? Icons.emoji_events_outlined
                          : Icons.check_circle_outline,
                      label: isClean ? 'Clean solve' : 'With help',
                      value: isClean ? '⭐' : '✓',
                    ),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pause overlay (topic-17 §4)
// ---------------------------------------------------------------------------

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onResume,
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_outline,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.9),
            ),
            const SizedBox(height: 16),
            Text(
              'Paused',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to continue',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check / Reveal overflow menu (topic-11)
// ---------------------------------------------------------------------------

enum _CheckRevealOption {
  checkLetter,
  checkWord,
  checkPuzzle,
  divider,
  revealLetter,
  revealWord,
  revealPuzzle,
  divider2,
  resetPuzzle,
}

class _CheckRevealMenu extends ConsumerWidget {
  const _CheckRevealMenu({required this.puzzleId});
  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_CheckRevealOption>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Check / Reveal',
      onSelected: (option) => _onSelected(context, ref, option),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _CheckRevealOption.checkLetter,
          child: Text('Check letter'),
        ),
        PopupMenuItem(
          value: _CheckRevealOption.checkWord,
          child: Text('Check word'),
        ),
        PopupMenuItem(
          value: _CheckRevealOption.checkPuzzle,
          child: Text('Check puzzle'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _CheckRevealOption.revealLetter,
          child: Text('Reveal letter'),
        ),
        PopupMenuItem(
          value: _CheckRevealOption.revealWord,
          child: Text('Reveal word'),
        ),
        PopupMenuItem(
          value: _CheckRevealOption.revealPuzzle,
          child: Text('Reveal puzzle'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _CheckRevealOption.resetPuzzle,
          child: Text('Reset puzzle'),
        ),
      ],
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    _CheckRevealOption option,
  ) async {
    final notifier = ref.read(solveProvider(puzzleId).notifier);

    switch (option) {
      case _CheckRevealOption.checkLetter:
        notifier.checkCell();
      case _CheckRevealOption.checkWord:
        notifier.checkWord();
      case _CheckRevealOption.checkPuzzle:
        notifier.checkGrid();
      case _CheckRevealOption.revealLetter:
        notifier.revealCell();
      case _CheckRevealOption.revealWord:
        notifier.revealWord();
      case _CheckRevealOption.revealPuzzle:
        // Confirm before revealing the whole puzzle (topic-11)
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reveal puzzle?'),
            content: const Text(
              'This will fill the whole puzzle. The solve will not count toward your streak.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Reveal'),
              ),
            ],
          ),
        );
        if (confirmed == true) notifier.revealPuzzle();
      case _CheckRevealOption.resetPuzzle:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reset puzzle?'),
            content: const Text(
              'All your progress, checks, and reveals will be cleared. '
              'The timer will restart from zero.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Reset'),
              ),
            ],
          ),
        );
        if (confirmed == true) notifier.resetPuzzle();
      case _CheckRevealOption.divider:
      case _CheckRevealOption.divider2:
        break;
    }
  }
}

// ---------------------------------------------------------------------------
// Timer display
// ---------------------------------------------------------------------------

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.seconds, required this.isPaused});

  final int seconds;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final text =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPaused) ...[
          const Icon(Icons.pause, size: 16),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontFamily: 'RobotoMono',
              ),
        ),
      ],
    );
  }
}
