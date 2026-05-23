import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/puzzle_size_bucket.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/check_result.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/models/solve_errors.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/widgets/clue_panel.dart';
import 'package:crosscue/features/solve/presentation/widgets/completion_sheet.dart';
import 'package:crosscue/features/solve/presentation/widgets/crossword_grid.dart'
    show CrosswordGrid, showRebusDialogForFocus;
import 'package:crosscue/features/solve/presentation/widgets/crossword_keyboard.dart';
import 'package:crosscue/features/solve/presentation/widgets/pause_overlay.dart';
import 'package:crosscue/features/solve/presentation/widgets/solve_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _hapticsEnabled = true;
  bool _soundsEnabled = false;

  // Latest snapshot of the solve provider's state, kept in sync via the
  // listener installed in initState. Cached so dispose() can decide whether
  // to flush the autosave without calling ref.read — Riverpod forbids `ref`
  // use during element deactivation (the framework throws StateError).
  SolveState? _lastSolveState;

  // Cached notifier reference. Captured once in initState so dispose() can
  // call flushPendingSave() without going through `ref`. The notifier itself
  // outlives the widget (Riverpod owns its lifecycle).
  SolveNotifier? _solveNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
    _solveNotifier = ref.read(solveProvider(widget.puzzleId).notifier);
    ref.listenManual(solveProvider(widget.puzzleId), _onSolveStateChanged);
    ref.listenManual(
      hapticsEnabledProvider,
      (_, next) => _hapticsEnabled = next,
      fireImmediately: true,
    );
    ref.listenManual(
      soundsEnabledProvider,
      (_, next) => _soundsEnabled = next,
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    // Backstop for the unawaited markComplete in SolveNotifier._persistCompletion:
    // on a normal screen tear-down where the puzzle is already terminal, flush
    // the autosave so solve_sessions reflects the completed status even if the
    // markComplete write is still in flight or fails. See
    // docs/architecture/completion-authority.md (divergence window 1).
    //
    // _lastSolveState + _solveNotifier are cached during initState/listen
    // because Riverpod's `ref` is unsafe to use here (the widget is being
    // deactivated). Caught by integration_test/seed_and_solve_test.dart.
    final solveState = _lastSolveState;
    final notifier = _solveNotifier;
    if (solveState != null &&
        solveState.status.isTerminal &&
        notifier != null) {
      unawaited(notifier.flushPendingSave());
    }
    _confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Solve-screen lifecycle observer — one of exactly two observers in the
  /// app.
  ///
  /// Responsibility split:
  ///   - This observer handles `paused` / `hidden` (auto-pause the puzzle
  ///     timer) and `detached` (flush any pending save).
  ///   - The app-level [`_CrosshareLifecycleObserver`] in `app.dart`
  ///     handles `resumed` (retrigger Crosshare auto-download).
  ///
  /// Do not add a third observer elsewhere. See the policy comment on
  /// `_CrosshareLifecycleObserver` and the guard test at
  /// `test/architecture/lifecycle_observers_test.dart`.
  ///
  /// Auto-resume from pause is handled by the overlay tap, see
  /// [_PauseOverlay].
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

  void _playFeedbackSound({bool? soundsEnabled}) {
    if (soundsEnabled ?? _soundsEnabled) {
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

    if (_hapticsEnabled) {
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
        builder: (ctx) => CompletionSheet(
          solveState: solveState,
          onViewGrid: () => Navigator.of(ctx).pop(),
          onNextPuzzle: () {
            Navigator.of(ctx).pop();
            if (mounted) context.go(Routes.home);
          },
          onResetPuzzle: () {
            Navigator.of(ctx).pop();
            if (!mounted) return;
            _completionSheetShown = false;
            ref.read(solveProvider(widget.puzzleId).notifier).resetPuzzle();
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

  void _onSolveStateChanged(
    AsyncValue<SolveState>? previous,
    AsyncValue<SolveState> next,
  ) {
    next.whenData((solveState) {
      // Cache so dispose() can read the latest terminal status without
      // calling ref.read on an unmounted ConsumerStatefulElement.
      _lastSolveState = solveState;
      // If a reset returned the puzzle to in-progress, allow the completion
      // sheet to fire again on the next solve.
      if (_completionSheetShown &&
          solveState.status == PuzzleStatus.inProgress) {
        _completionSheetShown = false;
      }
      _maybeShowCompletionSheet(solveState);
      _syncClueSelectors(solveState);
    });
  }

  void _syncClueSelectors(SolveState solveState) {
    final nextActiveClue = solveState.activeClue;
    final nextCrossClue = solveState.crossClue;
    final puzzleChanged = _selectorPuzzleId != solveState.puzzle.id;
    final activeChanged = !_sameClue(_selectedActiveClue, nextActiveClue);
    final crossChanged = !_sameClue(_selectedCrossClue, nextCrossClue);
    if (!puzzleChanged && !activeChanged && !crossChanged) return;

    _selectorPuzzleId = solveState.puzzle.id;
    if (!mounted) return;
    setState(() {
      _selectedActiveClue = nextActiveClue;
      _selectedCrossClue = nextCrossClue;
    });
  }

  bool _sameClue(Clue? a, Clue? b) {
    return a?.number == b?.number && a?.direction == b?.direction;
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
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);
    final soundsEnabled = ref.watch(soundsEnabledProvider);

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
          resizeToAvoidBottomInset: false,
          appBar: SolveAppBar(
            puzzleId: widget.puzzleId,
            title: puzzle.metadata.title,
            solveState: solveState,
            isComplete: isComplete,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grid — capped at 55% of body height so CluePanel and
                    // keyboard always have room. CrosswordGrid's internal
                    // LayoutBuilder sizes cells by min(width/cols, height/rows)
                    // so it renders correctly within any tight height bound.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.55,
                      ),
                      child: CrosswordGrid(
                        puzzleId: widget.puzzleId,
                        solveState: solveState,
                        onGridFocusSelected: (focus) =>
                            _setSelectorsFromFocus(solveState, focus),
                      ),
                    ),

                    // Clue panel — Expanded with no flex competitors so it
                    // takes exactly the space between grid and keyboard,
                    // leaving zero free space that could float the keyboard up.
                    Expanded(
                      child: CluePanel(
                        solveState: solveState,
                        activeClue: selectedActiveClue,
                        crossClue: selectedCrossClue,
                        hapticsEnabled: hapticsEnabled,
                        onClueTap: (clue) {
                          if (hapticsEnabled) HapticFeedback.selectionClick();
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
                        isSmallPuzzle:
                            puzzle.sizeBucket == PuzzleSizeBucket.mini,
                        hapticsEnabled: hapticsEnabled,
                        soundsEnabled: soundsEnabled,
                        onFeedbackSound: () =>
                            _playFeedbackSound(soundsEnabled: soundsEnabled),
                        onLetter: (l) {
                          final wordComplete = ref
                              .read(solveProvider(widget.puzzleId).notifier)
                              .inputLetter(l);
                          if (wordComplete && hapticsEnabled) {
                            HapticFeedback.mediumImpact();
                          }
                          if (wordComplete) {
                            _playFeedbackSound(soundsEnabled: soundsEnabled);
                          }
                        },
                        onBackspace: () => ref
                            .read(solveProvider(widget.puzzleId).notifier)
                            .backspace(),
                        onCheckWord: () {
                          final result = ref
                              .read(solveProvider(widget.puzzleId).notifier)
                              .checkWord();
                          if (result.shouldVibrate && hapticsEnabled) {
                            HapticFeedback.vibrate();
                          }
                          if (result == CheckResult.allCorrect) {
                            _playFeedbackSound(soundsEnabled: soundsEnabled);
                          }
                        },
                        onRebus: () => _openRebusDialog(
                          context: context,
                          solveState: solveState,
                          hapticsEnabled: hapticsEnabled,
                          soundsEnabled: soundsEnabled,
                        ),
                      ),

                    // Bottom safe-area padding
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),

                // Pause overlay — shown when paused and puzzle not yet complete
                if (solveState.isPaused && !isComplete)
                  PauseOverlay(
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
          ),
        );
      },
    );
  }

  /// Opens the rebus entry dialog for the currently focused cell.
  /// Called from the soft keyboard's "Rebus" key. The long-press menu has
  /// its own entry point inside [CrosswordGrid].
  void _openRebusDialog({
    required BuildContext context,
    required SolveState solveState,
    required bool hapticsEnabled,
    required bool soundsEnabled,
  }) {
    if (hapticsEnabled) HapticFeedback.lightImpact();
    final focus = solveState.focus;
    final currentLetter = solveState.progress.cell(focus.row, focus.col).letter;
    unawaited(
      showRebusDialogForFocus(
        context: context,
        ref: ref,
        puzzleId: widget.puzzleId,
        currentLetter: currentLetter,
      ).then((wordComplete) {
        if (wordComplete == true) {
          if (hapticsEnabled) HapticFeedback.mediumImpact();
          _playFeedbackSound(soundsEnabled: soundsEnabled);
        }
      }),
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
