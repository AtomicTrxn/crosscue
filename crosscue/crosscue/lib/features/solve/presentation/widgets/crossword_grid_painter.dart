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
  });

  final Puzzle puzzle;
  final Grid<CellProgress> progress;
  final SolveState solveState;
  final CrosswordTheme theme;

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

        // Background color
        if (solveState.isFocused(r, c)) {
          bgPaint.color = theme.cellActive;
        } else if (solveState.isWordHighlighted(r, c)) {
          bgPaint.color = theme.wordHighlight;
        } else if (solveState.isCrossHighlighted(r, c)) {
          bgPaint.color = theme.crossHighlight;
        } else {
          bgPaint.color = _cellBg(prog);
        }
        canvas.drawRect(rect, bgPaint);

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
          _paintLetter(canvas, prog.letter, rect, cellSize);
        }
      }
    }

    // Outer border
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, totalW, totalH),
      outerBorderPaint,
    );
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
    final fontSize = (cellSize * CrosscueTypography.cellNumberFactor).clamp(7.0, 14.0);
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
    double cellSize,
  ) {
    final fontSize = (cellSize * CrosscueTypography.cellLetterFactor).clamp(10.0, 32.0);
    // Revealed cells use standard cellText — the stateRevealed background
    // (pale yellow) communicates the revealed state visually.
    final color = theme.cellText;

    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontFamily: 'RobotoMono',
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
        oldDelegate.solveState.focus != solveState.focus ||
        oldDelegate.solveState.status != solveState.status;
  }
}
