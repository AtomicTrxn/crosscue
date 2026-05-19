import 'dart:math' as math;

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:flutter/material.dart';

/// Paints the crossword grid using direct canvas calls.
class CrosswordGridPainter extends CustomPainter {
  CrosswordGridPainter({
    required this.puzzle,
    required this.progress,
    required this.solveState,
    required this.theme,
    required this.colorblindMode,
    this.previousSolveState,
    this.effects = const {},
    this.effectValue = 1.0,
  });

  final Puzzle puzzle;
  final Grid<CellProgress> progress;
  final SolveState solveState;
  final CrosswordTheme theme;
  final ColorblindMode colorblindMode;
  final SolveState? previousSolveState;
  final Map<(int, int), GridCellEffect> effects;
  final double effectValue;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / puzzle.width;
    final cellH = size.height / puzzle.height;
    final cellSize = cellW < cellH ? cellW : cellH;

    final totalW = cellSize * puzzle.width;
    final totalH = cellSize * puzzle.height;
    final offsetX = (size.width - totalW) / 2;
    final offsetY = (size.height - totalH) / 2;

    final bgPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = theme.gridBorder
      ..strokeWidth = 0.5;
    final outerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = theme.gridOuterBorder
      ..strokeWidth = 2.0;

    for (var r = 0; r < puzzle.height; r++) {
      for (var c = 0; c < puzzle.width; c++) {
        final rect = Rect.fromLTWH(
          offsetX + c * cellSize,
          offsetY + r * cellSize,
          cellSize,
          cellSize,
        );

        final cell = puzzle.grid.cell(r, c);

        if (cell.isBlack) {
          bgPaint.color = theme.gridBlack;
          canvas.drawRect(rect, bgPaint);
          continue;
        }

        final prog = progress.cell(r, c);
        final effect = effects[(r, c)];
        final isShaking = effect?.type == GridCellEffectType.checkIncorrect;
        if (isShaking) {
          final shake =
              math.sin(effectValue * math.pi * 6) * 4 * (1 - effectValue);
          canvas.save();
          canvas.translate(shake, 0);
        } else if (effect?.isFlip == true) {
          final scaleX = math.cos(effectValue * math.pi).abs().clamp(0.08, 1.0);
          canvas.save();
          canvas.translate(rect.center.dx, rect.center.dy);
          canvas.scale(scaleX, 1);
          canvas.translate(-rect.center.dx, -rect.center.dy);
        }

        final currentBg = _backgroundFor(solveState, progress, r, c);
        final previous = previousSolveState;
        final previousBg = previous == null
            ? currentBg
            : _backgroundFor(previous, previous.progress, r, c);

        // Background color. Focus and word-highlight changes cross-fade while
        // check/reveal effects still get their per-cell flip/shake treatment.
        bgPaint.color = Color.lerp(previousBg, currentBg, effectValue)!;
        canvas.drawRect(rect, bgPaint);
        if (effect?.type == GridCellEffectType.wordComplete ||
            effect?.type == GridCellEffectType.puzzleComplete) {
          final waveDelay = effect?.type == GridCellEffectType.puzzleComplete
              ? ((r + c) / (puzzle.width + puzzle.height)).clamp(0.0, 0.35)
              : 0.0;
          final waveValue = ((effectValue - waveDelay) / (1 - waveDelay)).clamp(
            0.0,
            1.0,
          );
          final pulse = math.sin(waveValue * math.pi).clamp(0.0, 1.0);
          final pulsePaint = Paint()
            ..style = PaintingStyle.fill
            ..color = theme.stateCorrect.withValues(alpha: 0.22 * pulse);
          canvas.drawRect(rect, pulsePaint);
        }

        // Cell border
        canvas.drawRect(rect, borderPaint);

        // Clue number
        if (cell.number != null) {
          _paintNumber(canvas, cell.number!, rect, cellSize);
        }

        // Circle annotation
        if (cell.circled) {
          final circlePaint = Paint()
            ..style = PaintingStyle.stroke
            ..color = theme.gridBorder
            ..strokeWidth = 1.5;
          canvas.drawCircle(rect.center, cellSize / 2 - 1, circlePaint);
        }

        // User letter
        if (prog.letter.isNotEmpty) {
          _paintLetter(
            canvas,
            prog.letter,
            rect,
            cellSize,
            color: _letterColorFor(r, c),
            scale: effect?.type == GridCellEffectType.entry
                ? 0.7 + (0.3 * effectValue)
                : 1.0,
            opacity:
                effect?.type == GridCellEffectType.entry ? effectValue : 1.0,
          );
        } else if (effect
            case GridCellEffect(
              type: GridCellEffectType.backspace,
              oldLetter: final oldLetter?,
            )) {
          _paintLetter(
            canvas,
            oldLetter,
            rect,
            cellSize,
            scale: 1.0 - (0.3 * effectValue),
            opacity: 1.0 - effectValue,
          );
        }

        _paintAccessibilityOverlay(canvas, prog, rect, cellSize, r, c);
        _paintStateGlyph(canvas, prog, rect, cellSize);

        if (isShaking || effect?.isFlip == true) {
          canvas.restore();
        }
      }
    }

    // Outer border
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, totalW, totalH),
      outerBorderPaint,
    );
  }

  Color _backgroundFor(
    SolveState state,
    Grid<CellProgress> grid,
    int row,
    int col,
  ) {
    if (state.isFocused(row, col)) {
      return theme.cellActive;
    }
    if (state.isWordHighlighted(row, col)) {
      return theme.wordHighlight;
    }
    if (_isCompletedCell(state, row, col)) {
      // Intentionally theme-fixed: completion is a celebration moment and
      // the bright green pair reads the same in light and dark mode.
      return CrosscueColors.completedCellBg;
    }
    return _cellBg(grid.cell(row, col));
  }

  Color _cellBg(CellProgress prog) {
    return switch (prog.state) {
      CellState.checkedCorrect => theme.gridEmpty,
      CellState.checkedIncorrect => theme.gridEmpty,
      CellState.revealed => theme.stateRevealed,
      _ => theme.gridEmpty,
    };
  }

  void _paintNumber(Canvas canvas, int number, Rect cellRect, double cellSize) {
    final fontSize = (cellSize * CrosscueTypography.cellNumberFactor).clamp(
      7.0,
      14.0,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          fontSize: fontSize,
          color: theme.cellNumber,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(cellRect.left + 1.5, cellRect.top + 1.0));
  }

  void _paintLetter(
    Canvas canvas,
    String letter,
    Rect cellRect,
    double cellSize, {
    Color? color,
    double scale = 1.0,
    double opacity = 1.0,
  }) {
    final baseFontSize = (cellSize * CrosscueTypography.cellLetterFactor).clamp(
      10.0,
      32.0,
    );
    // Revealed cells use standard cellText — the stateRevealed background
    // (pale yellow) communicates the revealed state visually.
    final effectiveColor = (color ?? theme.cellText).withValues(
      alpha: opacity.clamp(0.0, 1.0),
    );

    // Rebus cells: shrink the font so multi-letter (or PB/AU) answers fit
    // within the cell width minus a small padding. Lighter weight for
    // 3+ chars relieves visual density. Single-letter cells fall through
    // with no extra work.
    final isRebus = letter.length > 1;
    final fontWeight =
        isRebus && letter.length >= 3 ? FontWeight.w600 : FontWeight.bold;
    final autoshrunkFontSize = isRebus
        ? _fitRebusFontSize(letter, baseFontSize, cellSize)
        : baseFontSize;

    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: autoshrunkFontSize * scale,
          color: effectiveColor,
          fontFamily: CrosscueTypography.roboto,
          fontWeight: fontWeight,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: cellSize);

    tp.paint(
      canvas,
      Offset(
        cellRect.left + (cellSize - tp.width) / 2,
        cellRect.top + (cellSize - tp.height) / 2,
      ),
    );
  }

  /// Returns a font size that lets a multi-character rebus answer fit
  /// within a single cell on one line.
  ///
  /// Starts from [baseFontSize] and shrinks proportionally to fit
  /// `cellSize - 2 * inset`. Floors at 7 pt to remain legible even for
  /// 5–6 letter rebuses in a tiny mini-puzzle cell.
  double _fitRebusFontSize(
    String letter,
    double baseFontSize,
    double cellSize,
  ) {
    const minFontSize = 7.0;
    final maxTextWidth = cellSize - 4.0; // 2pt padding each side
    if (maxTextWidth <= 0) return minFontSize;

    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: baseFontSize,
          fontFamily: CrosscueTypography.roboto,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    if (tp.width <= maxTextWidth) return baseFontSize;
    final scaled = baseFontSize * (maxTextWidth / tp.width);
    return scaled < minFontSize ? minFontSize : scaled;
  }

  Color _letterColorFor(int row, int col) {
    final isCompleted = _isCompletedCell(solveState, row, col);
    final progress = solveState.progress.cell(row, col);
    if (colorblindMode == ColorblindMode.deuteranopia) {
      if (progress.state == CellState.checkedIncorrect) {
        return theme.colorblindIncorrectCellText;
      }
      if (progress.state == CellState.checkedCorrect || isCompleted) {
        return solveState.isFocused(row, col)
            ? theme.focusedCellText
            : theme.colorblindCorrectCellText;
      }
    }
    if (isCompleted) {
      return CrosscueColors.completedCellFg;
    }
    if (progress.state == CellState.checkedCorrect) {
      return solveState.isFocused(row, col)
          ? theme.correctFocusedCellText
          : theme.correctCellText;
    }
    if (progress.state == CellState.checkedIncorrect) {
      return theme.incorrectCellText;
    }
    if (solveState.isFocused(row, col)) {
      return theme.focusedCellText;
    }
    return theme.cellText;
  }

  bool _isCompletedCell(SolveState state, int row, int col) {
    final progress = state.progress.cell(row, col);
    if (progress.letter.isEmpty) return false;
    for (final clue in state.puzzle.clues) {
      if (!SolveState.cellInClue(row, col, clue)) continue;
      if (_isClueComplete(state, clue)) return true;
    }
    return false;
  }

  bool _isClueComplete(SolveState state, Clue clue) {
    for (var i = 0; i < clue.length; i++) {
      final (row, col) = clue.direction == Direction.across
          ? (clue.startRow, clue.startCol + i)
          : (clue.startRow + i, clue.startCol);
      final progress = state.progress.cell(row, col);
      final solutionCell = state.puzzle.grid.cell(row, col);
      // Match the completion rule so a "J" entry on a JACK rebus cell
      // still triggers the celebration green on the surrounding word.
      if (!solutionCell.accepts(progress.letter)) {
        return false;
      }
    }
    return true;
  }

  void _paintAccessibilityOverlay(
    Canvas canvas,
    CellProgress progress,
    Rect rect,
    double cellSize,
    int row,
    int col,
  ) {
    switch (colorblindMode) {
      case ColorblindMode.none:
        return;
      case ColorblindMode.deuteranopia:
        final isCompleted = _isCompletedCell(solveState, row, col);
        final isCorrect =
            progress.state == CellState.checkedCorrect || isCompleted;
        final isIncorrect = progress.state == CellState.checkedIncorrect;
        if (!isCorrect && !isIncorrect) return;
        _paintVerificationSymbol(
          canvas,
          rect,
          cellSize,
          symbol: isIncorrect ? '✗' : '✓',
          color: isIncorrect
              ? theme.colorblindIncorrectCellText
              : theme.colorblindCorrectCellText,
        );
    }
  }

  void _paintVerificationSymbol(
    Canvas canvas,
    Rect rect,
    double cellSize, {
    required String symbol,
    required Color color,
  }) {
    final fontSize = (cellSize * 0.18).clamp(8.0, 9.0);
    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(rect.right - tp.width - 3, rect.top + 2));
  }

  void _paintStateGlyph(
    Canvas canvas,
    CellProgress progress,
    Rect rect,
    double cellSize,
  ) {
    final glyphPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (cellSize * 0.045).clamp(1.0, 2.0)
      ..color = theme.cellText.withValues(alpha: 0.42);

    switch (progress.state) {
      case CellState.checkedIncorrect:
        final inset = (cellSize * 0.18).clamp(3.0, 8.0);
        canvas.drawLine(
          Offset(rect.right - inset, rect.top + inset),
          Offset(rect.right - inset * 1.9, rect.top + inset * 1.9),
          glyphPaint,
        );
      case CellState.revealed:
        final center = Offset(
          rect.right - (cellSize * 0.22).clamp(5.0, 10.0),
          rect.bottom - (cellSize * 0.20).clamp(5.0, 10.0),
        );
        final eyeRect = Rect.fromCenter(
          center: center,
          width: (cellSize * 0.22).clamp(5.0, 9.0),
          height: (cellSize * 0.12).clamp(3.0, 5.0),
        );
        canvas.drawOval(eyeRect, glyphPaint);
        canvas.drawCircle(
          center,
          (cellSize * 0.025).clamp(0.8, 1.4),
          Paint()
            ..style = PaintingStyle.fill
            ..color = glyphPaint.color,
        );
      default:
        return;
    }
  }

  @override
  bool shouldRepaint(CrosswordGridPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.theme != theme ||
        oldDelegate.previousSolveState != previousSolveState ||
        oldDelegate.effects != effects ||
        oldDelegate.effectValue != effectValue ||
        oldDelegate.colorblindMode != colorblindMode ||
        oldDelegate.solveState.focus != solveState.focus ||
        oldDelegate.solveState.status != solveState.status;
  }
}

enum GridCellEffectType {
  entry,
  backspace,
  checkCorrect,
  checkIncorrect,
  reveal,
  wordComplete,
  puzzleComplete,
}

class GridCellEffect {
  const GridCellEffect(this.type, {this.oldLetter});

  final GridCellEffectType type;
  final String? oldLetter;

  bool get isFlip =>
      type == GridCellEffectType.checkCorrect ||
      type == GridCellEffectType.checkIncorrect ||
      type == GridCellEffectType.reveal;
}
