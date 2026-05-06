import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/crossword_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/models/cell_progress.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/grid.dart';
import '../../domain/models/puzzle.dart';
import '../notifiers/solve_state.dart';

/// Paints the crossword grid using direct canvas calls.
class CrosswordGridPainter extends CustomPainter {
  CrosswordGridPainter({
    required this.puzzle,
    required this.progress,
    required this.solveState,
    required this.theme,
    this.previousSolveState,
    this.effects = const {},
    this.effectValue = 1.0,
  });

  final Puzzle puzzle;
  final Grid<CellProgress> progress;
  final SolveState solveState;
  final CrosswordTheme theme;
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
          final waveValue =
              ((effectValue - waveDelay) / (1 - waveDelay)).clamp(0.0, 1.0);
          final pulse = math.sin(waveValue * math.pi).clamp(0.0, 1.0);
          final pulsePaint = Paint()
            ..style = PaintingStyle.fill
            ..color =
                CrosscueColors.correctLight.withValues(alpha: 0.22 * pulse);
          canvas.drawRect(rect, pulsePaint);
        }

        // Cell border
        canvas.drawRect(rect, borderPaint);

        // Clue number
        if (cell.number != null) {
          _paintNumber(
            canvas,
            cell.number!,
            rect,
            cellSize,
          );
        }

        // Circle annotation
        if (cell.circled) {
          final circlePaint = Paint()
            ..style = PaintingStyle.stroke
            ..color = theme.gridBorder
            ..strokeWidth = 1.5;
          canvas.drawCircle(
            rect.center,
            cellSize / 2 - 1,
            circlePaint,
          );
        }

        // User letter
        if (prog.letter.isNotEmpty) {
          _paintLetter(
            canvas,
            prog.letter,
            rect,
            cellSize,
            scale: effect?.type == GridCellEffectType.entry
                ? 0.7 + (0.3 * effectValue)
                : 1.0,
            opacity:
                effect?.type == GridCellEffectType.entry ? effectValue : 1.0,
          );
        } else if (effect
            case GridCellEffect(
              type: GridCellEffectType.backspace,
              oldLetter: final oldLetter?
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
    if (state.isCrossHighlighted(row, col)) {
      return theme.crossHighlight;
    }
    return _cellBg(grid.cell(row, col));
  }

  Color _cellBg(CellProgress prog) {
    return switch (prog.state) {
      CellState.checkedCorrect => theme.stateCorrect,
      CellState.checkedIncorrect => theme.stateIncorrect,
      CellState.revealed => theme.stateRevealed,
      _ => theme.gridEmpty,
    };
  }

  void _paintNumber(
    Canvas canvas,
    int number,
    Rect cellRect,
    double cellSize,
  ) {
    final fontSize =
        (cellSize * CrosscueTypography.cellNumberFactor).clamp(7.0, 14.0);
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

    tp.paint(
      canvas,
      Offset(cellRect.left + 1.5, cellRect.top + 1.0),
    );
  }

  void _paintLetter(
    Canvas canvas,
    String letter,
    Rect cellRect,
    double cellSize, {
    double scale = 1.0,
    double opacity = 1.0,
  }) {
    final fontSize =
        (cellSize * CrosscueTypography.cellLetterFactor).clamp(10.0, 32.0);
    // Revealed cells use standard cellText — the stateRevealed background
    // (pale yellow) communicates the revealed state visually.
    final color = theme.cellText.withValues(alpha: opacity.clamp(0.0, 1.0));

    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize * scale,
          color: color,
          fontFamily: CrosscueTypography.roboto,
          fontWeight: FontWeight.bold,
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

  @override
  bool shouldRepaint(CrosswordGridPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.theme != theme ||
        oldDelegate.previousSolveState != previousSolveState ||
        oldDelegate.effects != effects ||
        oldDelegate.effectValue != effectValue ||
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
