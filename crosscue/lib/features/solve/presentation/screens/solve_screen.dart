import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
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
import 'package:crosscue/features/solve/presentation/widgets/crossword_grid.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
    ref.listenManual(solveProvider(widget.puzzleId), _onSolveStateChanged);
    ref.listenManual(
      hapticsEnabledProvider,
      (_, next) => _hapticsEnabled = _settingValue(next, fallback: true),
      fireImmediately: true,
    );
    ref.listenManual(
      soundsEnabledProvider,
      (_, next) => _soundsEnabled = _settingValue(next, fallback: false),
      fireImmediately: true,
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

  bool _settingValue(AsyncValue<bool> value, {required bool fallback}) {
    return value.when(
      data: (v) => v,
      loading: () => fallback,
      error: (_, __) => fallback,
    );
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
    final hapticsEnabled = _settingValue(
      ref.watch(hapticsEnabledProvider),
      fallback: true,
    );
    final soundsEnabled = _settingValue(
      ref.watch(soundsEnabledProvider),
      fallback: false,
    );

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
                        isSmallPuzzle: puzzle.width <= 7 && puzzle.height <= 7,
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
