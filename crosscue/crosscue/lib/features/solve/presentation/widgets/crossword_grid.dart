import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/crossword_theme.dart';
import '../notifiers/solve_notifier.dart';
import '../notifiers/solve_state.dart';
import 'crossword_grid_painter.dart';

/// The interactive crossword grid.
///
/// Handles:
///  - Touch/tap → cell focus
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

class _CrosswordGridState extends ConsumerState<CrosswordGrid> {
  final _focusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Attach physical-keyboard handler directly to the FocusNode so the
    // TextField is the sole widget owner of the node (avoids the
    // "child into parent of itself" assertion).
    _focusNode.onKeyEvent = _onKeyEvent;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _requestFocus() {
    _focusNode.requestFocus();
  }

  void _onTap(BuildContext context, Offset localPosition, double cellSize,
      double offsetX, double offsetY) {
    final puzzle = widget.solveState.puzzle;
    final col = ((localPosition.dx - offsetX) / cellSize).floor();
    final row = ((localPosition.dy - offsetY) / cellSize).floor();

    if (row < 0 ||
        row >= puzzle.height ||
        col < 0 ||
        col >= puzzle.width) {
      return;
    }

    ref.read(solveProvider(widget.puzzleId).notifier).tapCell(row, col);
    _requestFocus();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final notifier =
        ref.read(solveProvider(widget.puzzleId).notifier);

    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      notifier.backspace();
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && char.isNotEmpty) {
      notifier.inputLetter(char);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.solveState.puzzle;
    final xwTheme = Theme.of(context).extension<CrosswordTheme>() ??
        CrosswordTheme.light();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth / puzzle.width)
            .clamp(0.0, constraints.maxHeight / puzzle.height);
        final totalW = cellSize * puzzle.width;
        final totalH = cellSize * puzzle.height;
        final offsetX = (constraints.maxWidth - totalW) / 2;
        final offsetY = (constraints.maxHeight - totalH) / 2;

        return Stack(
          children: [
            // Grid painter
            GestureDetector(
              onTapDown: (details) => _onTap(
                context,
                details.localPosition,
                cellSize,
                offsetX,
                offsetY,
              ),
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: CrosswordGridPainter(
                  puzzle: puzzle,
                  progress: widget.solveState.progress,
                  solveState: widget.solveState,
                  theme: xwTheme,
                  textTheme: Theme.of(context).textTheme,
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
                      ref
                          .read(solveProvider(widget.puzzleId).notifier)
                          .inputLetter(last);
                    }
                    // Reset so every keystroke is detected as a change
                    _textController.clear();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
