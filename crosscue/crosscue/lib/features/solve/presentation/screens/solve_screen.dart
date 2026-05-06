import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/settings/settings_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../stats/presentation/providers/stats_providers.dart';
import '../../domain/models/enums.dart';
import '../notifiers/solve_notifier.dart';
import '../notifiers/solve_state.dart';
import '../widgets/clue_bar.dart';
import '../widgets/clue_panel.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/crossword_keyboard.dart';

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
        // Deep navy overlay (spec §08: rgba(10,42,110,0.88))
        barrierColor: const Color(0xE10A2A6E),
        builder: (ctx) => _CompletionSheet(
          solveState: solveState,
          onViewGrid: () => Navigator.of(ctx).pop(),
          onNextPuzzle: () {
            Navigator.of(ctx).pop();
            if (mounted) context.go(Routes.home);
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
          // Keep layout stable when the soft keyboard appears.
          // The hidden TextField driving input is off-screen at (-200,-200);
          // the grid never reflects when the OS keyboard slides up.
          // See ISSUES.md #4.
          resizeToAvoidBottomInset: false,
          appBar: _SolveAppBar(
            puzzleId: widget.puzzleId,
            title: puzzle.metadata.title,
            solveState: solveState,
            isComplete: isComplete,
          ),
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ClueBar — tappable to toggle direction
                  ClueBar(
                    solveState: solveState,
                    onToggleDirection: () => ref
                        .read(solveProvider(widget.puzzleId).notifier)
                        .toggleDirection(),
                  ),

                  // Full-width grid — self-sizes its height
                  CrosswordGrid(
                    puzzleId: widget.puzzleId,
                    solveState: solveState,
                  ),

                  // Two-column clue panel — takes remaining vertical space
                  Expanded(
                    child: CluePanel(solveState: solveState),
                  ),

                  // Custom QWERTY keyboard
                  if (!isComplete)
                    CrosswordKeyboard(
                      hapticsEnabled: _hapticsOn,
                      onLetter: (l) => ref
                          .read(solveProvider(widget.puzzleId).notifier)
                          .inputLetter(l),
                      onBackspace: () => ref
                          .read(solveProvider(widget.puzzleId).notifier)
                          .backspace(),
                      onCheckWord: () => ref
                          .read(solveProvider(widget.puzzleId).notifier)
                          .checkWord(),
                    ),

                  // Bottom safe-area padding
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
// Compact solve AppBar (48dp, Sprint 10)
// ---------------------------------------------------------------------------

class _SolveAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _SolveAppBar({
    required this.puzzleId,
    required this.title,
    required this.solveState,
    required this.isComplete,
  });

  final String puzzleId;
  final String title;
  final SolveState solveState;
  final bool isComplete;

  @override
  Size get preferredSize =>
      const Size.fromHeight(CrosscueSpacing.appBarHeightSolve);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      toolbarHeight: CrosscueSpacing.appBarHeightSolve,
      leading: BackButton(onPressed: () => context.pop()),
      centerTitle: true,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Timer — tap to pause/resume (topic-17 §4)
        GestureDetector(
          onTap: () {
            final notifier = ref.read(solveProvider(puzzleId).notifier);
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
        // Check / Reveal overflow menu
        if (!isComplete) _CheckRevealMenu(puzzleId: puzzleId),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Completion bottom sheet — spec §08
// ---------------------------------------------------------------------------

class _CompletionSheet extends ConsumerWidget {
  const _CompletionSheet({
    required this.solveState,
    required this.onViewGrid,
    required this.onNextPuzzle,
  });

  final SolveState solveState;
  final VoidCallback onViewGrid;
  final VoidCallback onNextPuzzle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = solveState.status;
    final isRevealed = status == PuzzleStatus.revealed;

    // Solve label per spec §08 + topic-11 completion types
    final solveLabel = switch (status) {
      PuzzleStatus.solved => 'Clean solve',
      PuzzleStatus.solvedWithHelp => 'Solved with checks',
      PuzzleStatus.revealed => 'Puzzle revealed',
      _ => 'Completed',
    };

    final m = solveState.elapsedSeconds ~/ 60;
    final s = solveState.elapsedSeconds % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    // Read streak from stats (may or may not include this solve yet)
    final statsAsync = ref.watch(statsDataProvider);
    final streak = statsAsync.asData?.value.currentStreak ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.35,
      maxChildSize: 0.75,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CrosscueSpacing.sheetRadius),
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              CrosscueSpacing.screenH,
              12,
              CrosscueSpacing.screenH,
              24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle — 36×4dp (spec §08)
                Container(
                  width: CrosscueSpacing.dragHandleW,
                  height: CrosscueSpacing.dragHandleH,
                  decoration: BoxDecoration(
                    color: CrosscueColors.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Solve label — 14px w600 #1A1A1A (spec §08)
                Text(
                  solveLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CrosscueColors.onSurface1Light,
                  ),
                ),
                const SizedBox(height: 8),

                // Time — 52px Roboto Mono w700 letterSpacing -2 (spec §08)
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: CrosscueTypography.robotoMono,
                    fontSize: CrosscueTypography.timerLarge,
                    fontWeight: FontWeight.w700,
                    color: CrosscueColors.onSurface1Light,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: CrosscueColors.dividerLight),
                const SizedBox(height: 12),

                // Streak row — 🔥 + "N-day streak" 15px w600 (spec §08)
                if (streak > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '$streak-day streak',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CrosscueColors.onSurface1Light,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: CrosscueColors.dividerLight),
                ],

                const SizedBox(height: 16),

                // Share result — outlined, hidden if revealed (spec §08)
                if (!isRevealed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Sharing coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CrosscueColors.onSurface2Light,
                        side: const BorderSide(
                          color: CrosscueColors.dividerLight,
                          width: 1,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Share result'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // View filled grid — text button 13px #999999 (spec §08)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onViewGrid,
                    style: TextButton.styleFrom(
                      foregroundColor: CrosscueColors.onSurface3Light,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    child: const Text('View filled grid'),
                  ),
                ),
                const SizedBox(height: 8),

                // Next puzzle — filled #1565C0 15px w600 (spec §08)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onNextPuzzle,
                    style: FilledButton.styleFrom(
                      backgroundColor: CrosscueColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Next puzzle'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          const Icon(Icons.pause, size: 14),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          style: context.timerStyle,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
