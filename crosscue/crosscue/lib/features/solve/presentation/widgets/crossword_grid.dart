import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/settings_providers.dart';
import '../../../../core/theme/crossword_theme.dart';
import '../notifiers/solve_notifier.dart';
import '../notifiers/solve_state.dart';
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

  bool get _hapticsOn {
    final async = ref.read(hapticsEnabledProvider);
    return async.when(data: (v) => v, loading: () => true, error: (_, __) => true);
  }

  void _onTap(BuildContext context, Offset localPosition, double cellSize,
      double offsetX, double offsetY) {
    final puzzle = widget.solveState.puzzle;
    final col = ((localPosition.dx - offsetX) / cellSize).floor();
    final row = ((localPosition.dy - offsetY) / cellSize).floor();

    if (row < 0 || row >= puzzle.height || col < 0 || col >= puzzle.width) return;

    if (_hapticsOn) HapticFeedback.selectionClick();
    ref.read(solveProvider(widget.puzzleId).notifier).tapCell(row, col);
    _requestFocus();
  }

  void _onLongPress(BuildContext context, Offset localPosition, double cellSize,
      double offsetX, double offsetY) {
    final puzzle = widget.solveState.puzzle;
    final col = ((localPosition.dx - offsetX) / cellSize).floor();
    final row = ((localPosition.dy - offsetY) / cellSize).floor();

    if (row < 0 || row >= puzzle.height || col < 0 || col >= puzzle.width) return;
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
        PopupMenuItem(value: _CellAction.checkLetter, child: Text('Check letter')),
        PopupMenuItem(value: _CellAction.checkWord, child: Text('Check word')),
        PopupMenuDivider(),
        PopupMenuItem(value: _CellAction.revealLetter, child: Text('Reveal letter')),
        PopupMenuItem(value: _CellAction.revealWord, child: Text('Reveal word')),
      ],
    ).then((action) {
      if (action == null) return;
      final notifier = ref.read(solveProvider(widget.puzzleId).notifier);
      switch (action) {
        case _CellAction.checkLetter:
          notifier.checkCell();
        case _CellAction.checkWord:
          notifier.checkWord();
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
      notifier.inputLetter(char);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.solveState.puzzle;
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();

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
              onLongPressStart: (details) => _onLongPress(
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

// Actions available from the long-press cell menu
enum _CellAction { checkLetter, checkWord, revealLetter, revealWord }
