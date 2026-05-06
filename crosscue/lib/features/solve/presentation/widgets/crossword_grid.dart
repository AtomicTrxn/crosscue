import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/features/solve/domain/models/clue.dart';
import 'package:crosscue/features/solve/domain/models/enums.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'crossword_grid_painter.dart';

/// The interactive crossword grid.
///
/// Handles:
///  - Tap → cell focus + optional haptic feedback
///  - Long-press → contextual Check/Reveal popup menu (ISSUES #2)
///  - Physical keyboard → letter input / backspace
///  - Soft keyboard → via hidden TextField overlay
class CrosswordGrid extends ConsumerStatefulWidget {
  const CrosswordGrid({
    super.key,
    required this.puzzleId,
    required this.solveState,
  });

  final String puzzleId;
  final SolveState solveState;

  @override
  ConsumerState<CrosswordGrid> createState() => _CrosswordGridState();
}

class _CrosswordGridState extends ConsumerState<CrosswordGrid>
    with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode();
  final _textController = TextEditingController();
  late final AnimationController _effectController;
  Map<(int, int), GridCellEffect> _effects = const {};
  SolveState? _previousSolveStateForEffect;

  @override
  void initState() {
    super.initState();
    _effectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Attach physical-keyboard handler directly to the FocusNode so the
    // TextField is the sole widget owner of the node (avoids the
    // "child into parent of itself" assertion).
    _focusNode.onKeyEvent = _onKeyEvent;
  }

  @override
  void didUpdateWidget(CrosswordGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startCellEffects(oldWidget.solveState, widget.solveState);
  }

  @override
  void dispose() {
    _effectController.dispose();
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _requestFocus() {
    _focusNode.requestFocus();
  }

  bool get _hapticsOn {
    final async = ref.read(hapticsEnabledProvider);
    return async.when(
        data: (v) => v, loading: () => true, error: (_, __) => true);
  }

  void _onTap(BuildContext context, Offset localPosition, double cellSize,
      double offsetX, double offsetY) {
    final puzzle = widget.solveState.puzzle;
    final col = ((localPosition.dx - offsetX) / cellSize).floor();
    final row = ((localPosition.dy - offsetY) / cellSize).floor();

    if (row < 0 || row >= puzzle.height || col < 0 || col >= puzzle.width) {
      return;
    }

    if (_hapticsOn) HapticFeedback.selectionClick();
    ref.read(solveProvider(widget.puzzleId).notifier).tapCell(row, col);
    _requestFocus();
  }

  void _onLongPress(BuildContext context, Offset localPosition, double cellSize,
      double offsetX, double offsetY) {
    final puzzle = widget.solveState.puzzle;
    final col = ((localPosition.dx - offsetX) / cellSize).floor();
    final row = ((localPosition.dy - offsetY) / cellSize).floor();

    if (row < 0 || row >= puzzle.height || col < 0 || col >= puzzle.width) {
      return;
    }
    // Don't show menu on black cells
    if (puzzle.grid.cell(row, col).isBlack) return;

    if (_hapticsOn) HapticFeedback.mediumImpact();

    // Focus the tapped cell first
    ref.read(solveProvider(widget.puzzleId).notifier).tapCell(row, col);
    _requestFocus();

    // Show contextual menu near the long-press location
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final globalPos = box.localToGlobal(localPosition);

    showMenu<_CellAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPos.dx, globalPos.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(
            value: _CellAction.checkLetter, child: Text('Check letter')),
        PopupMenuItem(value: _CellAction.checkWord, child: Text('Check word')),
        PopupMenuDivider(),
        PopupMenuItem(
            value: _CellAction.revealLetter, child: Text('Reveal letter')),
        PopupMenuItem(
            value: _CellAction.revealWord, child: Text('Reveal word')),
      ],
    ).then((action) {
      if (action == null) return;
      final notifier = ref.read(solveProvider(widget.puzzleId).notifier);
      switch (action) {
        case _CellAction.checkLetter:
          _vibrateIfIncorrect(notifier.checkCell());
        case _CellAction.checkWord:
          _vibrateIfIncorrect(notifier.checkWord());
        case _CellAction.revealLetter:
          notifier.revealCell();
        case _CellAction.revealWord:
          notifier.revealWord();
      }
    });
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final notifier = ref.read(solveProvider(widget.puzzleId).notifier);

    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      notifier.backspace();
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && char.isNotEmpty) {
      _pulseIfWordComplete(notifier.inputLetter(char));
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.solveState.puzzle;
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();
    final animationsDisabled = MediaQuery.of(context).disableAnimations;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Full-width layout: cell size driven by screen width (Sprint 10).
        // The widget sizes itself to exactly gridH tall so the parent Column
        // never needs to know the grid dimensions.
        final cellSize = constraints.maxWidth / puzzle.width;
        final gridH = cellSize * puzzle.height;

        return SizedBox(
          height: gridH,
          child: Stack(
            children: [
              // Grid painter
              GestureDetector(
                onTapDown: (details) => _onTap(
                  context,
                  details.localPosition,
                  cellSize,
                  0, // no horizontal offset — full width
                  0, // no vertical offset — exact height
                ),
                onLongPressStart: (details) => _onLongPress(
                  context,
                  details.localPosition,
                  cellSize,
                  0,
                  0,
                ),
                child: AnimatedBuilder(
                  animation: _effectController,
                  builder: (context, _) => CustomPaint(
                    size: Size(constraints.maxWidth, gridH),
                    painter: CrosswordGridPainter(
                      puzzle: puzzle,
                      progress: widget.solveState.progress,
                      solveState: widget.solveState,
                      theme: xwTheme,
                      previousSolveState: animationsDisabled
                          ? null
                          : _previousSolveStateForEffect,
                      effects: animationsDisabled ? const {} : _effects,
                      effectValue: animationsDisabled
                          ? 1.0
                          : Curves.easeOut.transform(_effectController.value),
                    ),
                  ),
                ),
              ),

              // Hidden TextField — sole owner of _focusNode.
              // Physical keyboard is handled via _focusNode.onKeyEvent (set in
              // initState). Soft keyboard input comes through onChanged.
              Positioned(
                left: -200,
                top: -200,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _textController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        // Backspace from soft keyboard
                        ref
                            .read(solveProvider(widget.puzzleId).notifier)
                            .backspace();
                      } else {
                        // New character appended
                        final last = value.characters.last;
                        _pulseIfWordComplete(
                          ref
                              .read(solveProvider(widget.puzzleId).notifier)
                              .inputLetter(last),
                        );
                      }
                      // Reset so every keystroke is detected as a change
                      _textController.clear();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pulseIfWordComplete(bool wordComplete) {
    if (wordComplete && _hapticsOn) {
      HapticFeedback.mediumImpact();
    }
  }

  void _vibrateIfIncorrect(CheckResult result) {
    if (result.shouldVibrate && _hapticsOn) {
      HapticFeedback.vibrate();
    }
  }

  void _startCellEffects(SolveState previous, SolveState current) {
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (animationsDisabled) {
      _effects = const {};
      _previousSolveStateForEffect = null;
      return;
    }

    final effects = <(int, int), GridCellEffect>{};
    final isCompleting = !_isTerminal(previous.status) &&
        _isTerminal(current.status) &&
        current.status != PuzzleStatus.revealed;

    for (var r = 0; r < current.puzzle.height; r++) {
      for (var c = 0; c < current.puzzle.width; c++) {
        if (current.puzzle.grid.cell(r, c).isBlack) continue;

        if (isCompleting) {
          effects[(r, c)] =
              const GridCellEffect(GridCellEffectType.puzzleComplete);
          continue;
        }

        final oldCell = previous.progress.cell(r, c);
        final newCell = current.progress.cell(r, c);
        if (oldCell == newCell) continue;

        final stateEffect = _stateEffect(oldCell.state, newCell.state);
        if (stateEffect != null) {
          effects[(r, c)] = GridCellEffect(stateEffect);
          continue;
        }

        if (oldCell.letter != newCell.letter) {
          if (newCell.letter.isNotEmpty) {
            effects[(r, c)] = const GridCellEffect(GridCellEffectType.entry);
          } else if (oldCell.letter.isNotEmpty) {
            effects[(r, c)] = GridCellEffect(
              GridCellEffectType.backspace,
              oldLetter: oldCell.letter,
            );
          }
        }
      }
    }

    for (final clue in current.puzzle.clues) {
      if (!_isWordComplete(previous, clue) && _isWordComplete(current, clue)) {
        for (final cell in _clueCells(clue)) {
          effects.putIfAbsent(
            cell,
            () => const GridCellEffect(GridCellEffectType.wordComplete),
          );
        }
      }
    }

    final highlightChanged = previous.focus != current.focus;
    if (effects.isEmpty && !highlightChanged) return;

    _effectController.stop();
    _effectController.duration = highlightChanged && effects.isEmpty
        ? _highlightDuration(previous, current)
        : _effectDuration(effects.values);
    setState(() {
      _effects = effects;
      _previousSolveStateForEffect = previous;
    });
    _effectController.forward(from: 0).whenComplete(() {
      if (mounted) {
        setState(() {
          _effects = const {};
          _previousSolveStateForEffect = null;
        });
      }
    });
  }

  GridCellEffectType? _stateEffect(CellState oldState, CellState newState) {
    if (oldState == newState) return null;
    return switch (newState) {
      CellState.checkedCorrect => GridCellEffectType.checkCorrect,
      CellState.checkedIncorrect => GridCellEffectType.checkIncorrect,
      CellState.revealed => GridCellEffectType.reveal,
      _ => null,
    };
  }

  Duration _effectDuration(Iterable<GridCellEffect> effects) {
    var millis = 0;
    for (final effect in effects) {
      millis = switch (effect.type) {
        GridCellEffectType.backspace => millis < 60 ? 60 : millis,
        GridCellEffectType.entry => millis < 80 ? 80 : millis,
        GridCellEffectType.checkIncorrect => millis < 200 ? 200 : millis,
        GridCellEffectType.wordComplete => millis < 300 ? 300 : millis,
        GridCellEffectType.puzzleComplete => millis < 500 ? 500 : millis,
        GridCellEffectType.checkCorrect ||
        GridCellEffectType.reveal =>
          millis < 400 ? 400 : millis,
      };
    }
    return Duration(milliseconds: millis == 0 ? 80 : millis);
  }

  Duration _highlightDuration(SolveState previous, SolveState current) {
    if (previous.focus.row == current.focus.row &&
        previous.focus.col == current.focus.col &&
        previous.focus.direction != current.focus.direction) {
      return const Duration(milliseconds: 200);
    }
    return const Duration(milliseconds: 150);
  }

  bool _isTerminal(PuzzleStatus status) =>
      status == PuzzleStatus.solved ||
      status == PuzzleStatus.solvedWithHelp ||
      status == PuzzleStatus.solvedWithReveal ||
      status == PuzzleStatus.revealed;

  bool _isWordComplete(SolveState state, Clue clue) {
    for (final (r, c) in _clueCells(clue)) {
      final progress = state.progress.cell(r, c);
      final solution = state.puzzle.grid.cell(r, c).solution;
      if (progress.letter.isEmpty ||
          progress.letter.toUpperCase() != solution.toUpperCase()) {
        return false;
      }
    }
    return true;
  }

  List<(int, int)> _clueCells(Clue clue) => [
        for (var i = 0; i < clue.length; i++)
          clue.direction == Direction.across
              ? (clue.startRow, clue.startCol + i)
              : (clue.startRow + i, clue.startCol),
      ];
}

// Actions available from the long-press cell menu
enum _CellAction { checkLetter, checkWord, revealLetter, revealWord }
