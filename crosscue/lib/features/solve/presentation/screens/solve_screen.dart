import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/app_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/utils/time_format.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/models/solve_errors.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/widgets/clue_panel.dart';
import 'package:crosscue/features/solve/presentation/widgets/crossword_grid.dart';
import 'package:crosscue/features/solve/presentation/widgets/crossword_keyboard.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';

class SolveScreen extends ConsumerStatefulWidget {
  const SolveScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen>
    with WidgetsBindingObserver {
  bool _completionSheetShown = false;
  late final ConfettiController _confettiController;
  String? _selectorPuzzleId;
  Clue? _selectedActiveClue;
  Clue? _selectedCrossClue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-pause when app goes to background; auto-resume is handled by the
  /// overlay tap (see [_PauseOverlay]).
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.hidden) {
      ref.read(solveProvider(widget.puzzleId).notifier).pause();
    } else if (lifecycleState == AppLifecycleState.detached) {
      unawaited(
        ref.read(solveProvider(widget.puzzleId).notifier).flushPendingSave(),
      );
    }
  }

  bool get _hapticsOn {
    final async = ref.read(hapticsEnabledProvider);
    return async.when(
      data: (v) => v,
      loading: () => true,
      error: (_, __) => true,
    );
  }

  bool get _soundsOn {
    final async = ref.read(soundsEnabledProvider);
    return async.when(
      data: (v) => v,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  void _playFeedbackSound() {
    if (_soundsOn) {
      unawaited(ref.read(soundPlayerProvider).playFeedback());
    }
  }

  void _maybeShowCompletionSheet(SolveState solveState) {
    final isComplete = solveState.status == PuzzleStatus.solved ||
        solveState.status == PuzzleStatus.solvedWithHelp ||
        solveState.status == PuzzleStatus.solvedWithReveal ||
        solveState.status == PuzzleStatus.revealed;
    if (!isComplete || _completionSheetShown) return;

    _completionSheetShown = true;

    if (_hapticsOn) {
      unawaited(_pulseCompletionHaptics());
    }
    _playFeedbackSound();

    // Wave flash (500ms) → confetti (800ms) → sheet slide up (350ms)
    final animationsDisabled = MediaQuery.of(context).disableAnimations;

    Future<void> showSheet() async {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        // Deep navy overlay (rgba(10,42,110,0.88))
        barrierColor: CrosscueColors.barrierDeepNavy,
        builder: (ctx) => _CompletionSheet(
          solveState: solveState,
          onViewGrid: () => Navigator.of(ctx).pop(),
          onNextPuzzle: () {
            Navigator.of(ctx).pop();
            if (mounted) context.go(Routes.home);
          },
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (animationsDisabled) {
        await showSheet();
        return;
      }
      // Wait for grid wave flash (500ms), then run confetti (800ms)
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _confettiController.play();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await showSheet();
    });
  }

  void _syncClueSelectors(SolveState solveState) {
    if (_selectorPuzzleId == solveState.puzzle.id) return;
    _selectorPuzzleId = solveState.puzzle.id;
    _selectedActiveClue = solveState.activeClue;
    _selectedCrossClue = solveState.crossClue;
  }

  void _setSelectorsFromFocus(SolveState solveState, FocusPosition focus) {
    setState(() {
      _selectedActiveClue = _clueForFocus(solveState, focus, focus.direction);
      _selectedCrossClue = _clueForFocus(
        solveState,
        focus,
        _oppositeDirection(focus.direction),
      );
    });
  }

  void _setSelectorsFromClue(SolveState solveState, Clue clue) {
    final focus = _focusForClue(solveState, clue);
    setState(() {
      _selectedActiveClue = clue;
      _selectedCrossClue = _clueForFocus(
        solveState,
        focus,
        _oppositeDirection(clue.direction),
      );
    });
  }

  FocusPosition _focusForClue(SolveState solveState, Clue clue) {
    var targetRow = clue.startRow;
    var targetCol = clue.startCol;
    for (final (row, col) in ClueProgressCalculator.cellsFor(clue)) {
      if (solveState.progress.cell(row, col).letter.isEmpty) {
        targetRow = row;
        targetCol = col;
        break;
      }
    }
    return FocusPosition(
      row: targetRow,
      col: targetCol,
      direction: clue.direction,
    );
  }

  Clue? _clueForFocus(
    SolveState solveState,
    FocusPosition focus,
    Direction direction,
  ) {
    for (final clue in solveState.puzzle.clues) {
      if (clue.direction == direction &&
          SolveState.cellInClue(focus.row, focus.col, clue)) {
        return clue;
      }
    }
    return null;
  }

  Direction _oppositeDirection(Direction direction) {
    return direction == Direction.across ? Direction.down : Direction.across;
  }

  @override
  Widget build(BuildContext context) {
    final solveAsync = ref.watch(solveProvider(widget.puzzleId));

    return solveAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        final message = switch (e) {
          PuzzleNotFoundError() =>
            'This puzzle no longer exists. It may have been deleted.',
          SolveSessionLoadError(:final cause) =>
            'Could not load session: $cause',
          _ => 'Could not load puzzle. Please go back and try again.',
        };
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (solveState) {
        _maybeShowCompletionSheet(solveState);
        _syncClueSelectors(solveState);

        final puzzle = solveState.puzzle;
        final selectedActiveClue = _selectedActiveClue ?? solveState.activeClue;
        final selectedCrossClue = _selectedCrossClue ?? solveState.crossClue;
        final isComplete = solveState.status == PuzzleStatus.solved ||
            solveState.status == PuzzleStatus.solvedWithHelp ||
            solveState.status == PuzzleStatus.solvedWithReveal ||
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
                  // Full-width grid — self-sizes its height
                  CrosswordGrid(
                    puzzleId: widget.puzzleId,
                    solveState: solveState,
                    onGridFocusSelected: (focus) =>
                        _setSelectorsFromFocus(solveState, focus),
                  ),

                  // Two-column clue panel — takes remaining vertical space
                  Expanded(
                    child: CluePanel(
                      solveState: solveState,
                      activeClue: selectedActiveClue,
                      crossClue: selectedCrossClue,
                      hapticsEnabled: _hapticsOn,
                      onClueTap: (clue) {
                        if (_hapticsOn) HapticFeedback.selectionClick();
                        _setSelectorsFromClue(solveState, clue);
                        ref
                            .read(solveProvider(widget.puzzleId).notifier)
                            .focusClue(clue);
                      },
                    ),
                  ),

                  // Custom QWERTY keyboard
                  if (!isComplete)
                    CrosswordKeyboard(
                      isSmallPuzzle: puzzle.width <= 7 && puzzle.height <= 7,
                      hapticsEnabled: _hapticsOn,
                      soundsEnabled: _soundsOn,
                      onFeedbackSound: _playFeedbackSound,
                      onLetter: (l) {
                        final wordComplete = ref
                            .read(solveProvider(widget.puzzleId).notifier)
                            .inputLetter(l);
                        if (wordComplete && _hapticsOn) {
                          HapticFeedback.mediumImpact();
                        }
                        if (wordComplete) {
                          _playFeedbackSound();
                        }
                      },
                      onBackspace: () => ref
                          .read(solveProvider(widget.puzzleId).notifier)
                          .backspace(),
                      onCheckWord: () {
                        final result = ref
                            .read(solveProvider(widget.puzzleId).notifier)
                            .checkWord();
                        if (result.shouldVibrate && _hapticsOn) {
                          HapticFeedback.vibrate();
                        }
                        if (result == CheckResult.allCorrect) {
                          _playFeedbackSound();
                        }
                      },
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

              // Confetti overlay — triggered on puzzle complete
              if (!MediaQuery.of(context).disableAnimations)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: 20,
                    gravity: 0.3,
                    colors: CrosscueColors.confettiPalette,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pulseCompletionHaptics() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(
        pattern: const [0, 35, 55, 55, 65, 80],
        intensities: const [90, 0, 160, 0, 255, 0],
      );
    } else {
      await HapticFeedback.heavyImpact();
    }
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

  /// Returns a human-readable source label for attribution display, or null
  /// for local imports (which need no attribution).
  String? _sourceLabel(String sourceId) {
    if (sourceId == 'local_import') return null;
    return switch (sourceId) {
      'crosshare_daily_mini' => 'via Crosshare',
      _ => 'via $sourceId',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceLabel = _sourceLabel(solveState.puzzle.metadata.sourceId);

    return AppBar(
      toolbarHeight: CrosscueSpacing.appBarHeightSolve,
      leading: BackButton(onPressed: () => context.pop()),
      centerTitle: true,
      title: sourceLabel != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sourceLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
              ],
            )
          : Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        // Timer — tap to pause/resume
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
// Completion bottom sheet
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

    // Solve label
    final solveLabel = switch (status) {
      PuzzleStatus.solved => 'Clean solve',
      PuzzleStatus.solvedWithHelp => 'Solved with checks',
      PuzzleStatus.solvedWithReveal => 'Solved with hints',
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
    final previousBest = solveState.previousPersonalBestMs;
    final elapsedMs = solveState.elapsedSeconds * 1000;
    final isNewPersonalBest = status == PuzzleStatus.solved &&
        previousBest != null &&
        elapsedMs < previousBest;

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
                // Drag handle — 36×4dp
                Container(
                  width: CrosscueSpacing.dragHandleW,
                  height: CrosscueSpacing.dragHandleH,
                  decoration: BoxDecoration(
                    color: CrosscueColors.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Solve label — 14px w600 #1A1A1A
                Text(
                  solveLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CrosscueColors.onSurface1Light,
                  ),
                ),
                const SizedBox(height: 8),

                // Time — 52px Roboto Mono w700 letterSpacing -2
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

                if (isNewPersonalBest) ...[
                  Text(
                    '↑ New personal best — prev. ${formatMs(previousBest)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CrosscueColors.correctLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: CrosscueColors.dividerLight),
                  const SizedBox(height: 12),
                ],

                // Streak row — 🔥 + "N-day streak" 15px w600
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

                // Share result — outlined, hidden if revealed
                if (!isRevealed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Share.share(
                          '${solveState.puzzle.metadata.title}\n'
                          '$timeStr - $solveLabel\n'
                          'Solved in Crosscue',
                          subject: 'Crosscue result',
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

                // View filled grid — text button 13px #999999
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

                // Next puzzle — filled #1565C0 15px w600
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
// Pause overlay
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
// Check / Reveal overflow menu
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
        _vibrateIfIncorrect(ref, notifier.checkCell());
      case _CheckRevealOption.checkWord:
        _vibrateIfIncorrect(ref, notifier.checkWord());
      case _CheckRevealOption.checkPuzzle:
        _vibrateIfIncorrect(ref, notifier.checkGrid());
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
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: CrosscueColors.primary,
                  foregroundColor: Colors.white,
                ),
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
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: CrosscueColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Colors.white,
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

  void _vibrateIfIncorrect(
    WidgetRef ref,
    CheckResult result,
  ) {
    final hapticsOn = ref.read(hapticsEnabledProvider).when(
          data: (value) => value,
          loading: () => true,
          error: (_, __) => true,
        );
    if (result.shouldVibrate && hapticsOn) {
      HapticFeedback.vibrate();
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
