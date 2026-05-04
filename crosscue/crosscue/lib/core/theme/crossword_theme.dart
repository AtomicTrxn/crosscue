import 'package:flutter/material.dart';

/// ThemeExtension carrying crossword-specific color tokens.
/// Widgets read from this extension instead of hardcoding colors.
///
/// Usage:
///   final xwTheme = Theme.of(context).extension<CrosswordTheme>()!;
///   paint.color = xwTheme.focusCellColor;
@immutable
class CrosswordTheme extends ThemeExtension<CrosswordTheme> {
  const CrosswordTheme({
    required this.focusCellColor,
    required this.wordHighlightColor,
    required this.crossHighlightColor,
    required this.blackCellColor,
    required this.gridLineColor,
    required this.cellNumberColor,
    required this.userLetterColor,
    required this.checkedCorrectColor,
    required this.checkedIncorrectColor,
    required this.revealedCellColor,
    required this.revealedLetterColor,
    required this.completionColor,
  });

  final Color focusCellColor;       // Active focused cell background
  final Color wordHighlightColor;   // Active word cells background
  final Color crossHighlightColor;  // Crossing word secondary highlight
  final Color blackCellColor;       // Black/filled squares
  final Color gridLineColor;        // Cell borders
  final Color cellNumberColor;      // Small clue numbers
  final Color userLetterColor;      // User's typed letters
  final Color checkedCorrectColor;  // Verified correct cell overlay
  final Color checkedIncorrectColor;// Verified incorrect cell overlay/shake
  final Color revealedCellColor;    // Background for revealed cells
  final Color revealedLetterColor;  // Letter color in revealed cells
  final Color completionColor;      // Accent for completion animation

  /// Default light theme tokens.
  factory CrosswordTheme.light() => const CrosswordTheme(
        focusCellColor: Color(0xFFFFEB3B),        // Amber 300
        wordHighlightColor: Color(0xFFFFF9C4),    // Yellow 100
        crossHighlightColor: Color(0xFFE3F2FD),   // Blue 50
        blackCellColor: Color(0xFF212121),         // Grey 900
        gridLineColor: Color(0xFFBDBDBD),          // Grey 400
        cellNumberColor: Color(0xFF757575),        // Grey 600
        userLetterColor: Color(0xFF212121),        // Near-black
        checkedCorrectColor: Color(0xFF81C784),    // Green 300
        checkedIncorrectColor: Color(0xFFE57373), // Red 300
        revealedCellColor: Color(0xFFE8EAF6),     // Indigo 50
        revealedLetterColor: Color(0xFF3F51B5),   // Indigo 500
        completionColor: Color(0xFF1565C0),        // Blue 800
      );

  /// Default dark theme tokens.
  factory CrosswordTheme.dark() => const CrosswordTheme(
        focusCellColor: Color(0xFFF9A825),        // Amber 800
        wordHighlightColor: Color(0xFF424242),    // Grey 800
        crossHighlightColor: Color(0xFF263238),   // Blue Grey 900
        blackCellColor: Color(0xFF000000),
        gridLineColor: Color(0xFF616161),          // Grey 700
        cellNumberColor: Color(0xFF9E9E9E),        // Grey 500
        userLetterColor: Color(0xFFEEEEEE),        // Grey 200
        checkedCorrectColor: Color(0xFF388E3C),    // Green 700
        checkedIncorrectColor: Color(0xFFC62828), // Red 800
        revealedCellColor: Color(0xFF283593),     // Indigo 800
        revealedLetterColor: Color(0xFFE8EAF6),   // Indigo 50
        completionColor: Color(0xFF42A5F5),        // Blue 400
      );

  @override
  CrosswordTheme copyWith({
    Color? focusCellColor,
    Color? wordHighlightColor,
    Color? crossHighlightColor,
    Color? blackCellColor,
    Color? gridLineColor,
    Color? cellNumberColor,
    Color? userLetterColor,
    Color? checkedCorrectColor,
    Color? checkedIncorrectColor,
    Color? revealedCellColor,
    Color? revealedLetterColor,
    Color? completionColor,
  }) {
    return CrosswordTheme(
      focusCellColor: focusCellColor ?? this.focusCellColor,
      wordHighlightColor: wordHighlightColor ?? this.wordHighlightColor,
      crossHighlightColor: crossHighlightColor ?? this.crossHighlightColor,
      blackCellColor: blackCellColor ?? this.blackCellColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      cellNumberColor: cellNumberColor ?? this.cellNumberColor,
      userLetterColor: userLetterColor ?? this.userLetterColor,
      checkedCorrectColor: checkedCorrectColor ?? this.checkedCorrectColor,
      checkedIncorrectColor:
          checkedIncorrectColor ?? this.checkedIncorrectColor,
      revealedCellColor: revealedCellColor ?? this.revealedCellColor,
      revealedLetterColor: revealedLetterColor ?? this.revealedLetterColor,
      completionColor: completionColor ?? this.completionColor,
    );
  }

  @override
  CrosswordTheme lerp(CrosswordTheme? other, double t) {
    if (other == null) return this;
    return CrosswordTheme(
      focusCellColor: Color.lerp(focusCellColor, other.focusCellColor, t)!,
      wordHighlightColor:
          Color.lerp(wordHighlightColor, other.wordHighlightColor, t)!,
      crossHighlightColor:
          Color.lerp(crossHighlightColor, other.crossHighlightColor, t)!,
      blackCellColor: Color.lerp(blackCellColor, other.blackCellColor, t)!,
      gridLineColor: Color.lerp(gridLineColor, other.gridLineColor, t)!,
      cellNumberColor: Color.lerp(cellNumberColor, other.cellNumberColor, t)!,
      userLetterColor: Color.lerp(userLetterColor, other.userLetterColor, t)!,
      checkedCorrectColor:
          Color.lerp(checkedCorrectColor, other.checkedCorrectColor, t)!,
      checkedIncorrectColor:
          Color.lerp(checkedIncorrectColor, other.checkedIncorrectColor, t)!,
      revealedCellColor:
          Color.lerp(revealedCellColor, other.revealedCellColor, t)!,
      revealedLetterColor:
          Color.lerp(revealedLetterColor, other.revealedLetterColor, t)!,
      completionColor: Color.lerp(completionColor, other.completionColor, t)!,
    );
  }
}
