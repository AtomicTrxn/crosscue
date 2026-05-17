// Crossword-specific color tokens as a ThemeExtension.
// Access via: Theme.of(context).extension<CrosswordTheme>()!
// Or via the convenience extension: context.cw

import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

@immutable
class CrosswordTheme extends ThemeExtension<CrosswordTheme> {
  const CrosswordTheme({
    required this.cellActive,
    required this.wordHighlight,
    required this.gridBlack,
    required this.gridEmpty,
    required this.gridBorder,
    required this.gridOuterBorder,
    required this.cellText,
    required this.cellNumber,
    required this.focusedCellText,
    required this.correctCellText,
    required this.correctFocusedCellText,
    required this.incorrectCellText,
    required this.colorblindCorrectCellText,
    required this.colorblindIncorrectCellText,
    required this.verificationUsesLetterColor,
    required this.stateCorrect,
    required this.stateIncorrect,
    required this.stateRevealed,
    required this.clueBarBg,
    required this.clueBarBorder,
    required this.clueBarDirection,
    required this.clueBarText,
    required this.activeClueBg,
    required this.cluePanelCrossRowBg,
    required this.keyboardBg,
    required this.keyDefault,
    required this.keySpecial,
    required this.keyCheck,
  });

  // ── Grid cell backgrounds ──────────────────────────────────────────────────
  /// Yellow — the focused cursor cell.
  final Color cellActive;

  /// Light blue — all cells in the active (across or down) word.
  final Color wordHighlight;

  /// Near-black — blocked/filled squares.
  final Color gridBlack;

  /// White/dark — empty cell background.
  final Color gridEmpty;

  // ── Grid borders ───────────────────────────────────────────────────────────
  /// Between cells — 0.5px stroke.
  final Color gridBorder;

  /// Outer grid border — 2px stroke.
  final Color gridOuterBorder;

  // ── Cell content ───────────────────────────────────────────────────────────
  /// User-entered letter color.
  final Color cellText;

  /// Clue number color (top-left of cell).
  final Color cellNumber;

  /// Letter color for focused cells on amber.
  final Color focusedCellText;

  /// Letter color for checked-correct cells when verification is text-based.
  final Color correctCellText;

  /// Letter color for checked-correct focused cells on amber.
  final Color correctFocusedCellText;

  /// Letter color for checked-incorrect cells when verification is text-based.
  final Color incorrectCellText;

  /// Color-blind-mode letter override for verified-correct cells.
  final Color colorblindCorrectCellText;

  /// Color-blind-mode letter override for verified-incorrect cells.
  final Color colorblindIncorrectCellText;

  /// Whether correct / incorrect verification is expressed by text color rather
  /// than by replacing the cell background.
  final bool verificationUsesLetterColor;

  // ── Check / reveal states ─────────────────────────────────────────────────
  /// Green tint — checked-correct cell background.
  final Color stateCorrect;

  /// Red tint — checked-incorrect cell background.
  final Color stateIncorrect;

  /// Pale yellow — revealed cell background.
  final Color stateRevealed;

  // ── ClueBar ────────────────────────────────────────────────────────────────
  /// ClueBar container background (primaryContainer).
  final Color clueBarBg;

  /// ClueBar bottom border.
  final Color clueBarBorder;

  /// Direction arrow color (↔ / ↕) and clue number label.
  final Color clueBarDirection;

  /// Clue text color in ClueBar.
  final Color clueBarText;

  // ── Clue panel active rows ─────────────────────────────────────────────────
  /// Active across-clue row highlight in clue panel.
  final Color activeClueBg;

  /// Active cross-clue row highlight in clue panel.
  /// v3.5: perpendicular highlighting was removed from the *grid*. This token
  /// remains for the clue-panel row tint only and is NOT a grid-state token.
  final Color cluePanelCrossRowBg;

  // ── Custom keyboard ────────────────────────────────────────────────────────
  /// Keyboard tray background.
  final Color keyboardBg;

  /// Standard letter key background.
  final Color keyDefault;

  /// Delete (⌫) key background.
  final Color keySpecial;

  /// Check-word (✓) key background.
  final Color keyCheck;

  // ── Factory constructors ──────────────────────────────────────────────────

  /// Build from a [ColorScheme]. Pass the scheme resolved by [AppTheme].
  /// Crossword grid, clue bar, keyboard, and state colors are intentionally
  /// fixed for readability and semantics; do not adapt them to Dynamic Color.
  factory CrosswordTheme.of(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    return CrosswordTheme(
      cellActive: isLight
          ? CrosscueColors.cellActiveLight
          : CrosscueColors.cellActiveDark,
      wordHighlight:
          isLight ? CrosscueColors.wordHLLight : CrosscueColors.wordHLDark,
      gridBlack: isLight
          ? CrosscueColors.gridBlackLight
          : CrosscueColors.gridBlackDark,
      gridEmpty: isLight
          ? CrosscueColors.gridEmptyLight
          : CrosscueColors.gridEmptyDark,
      gridBorder: isLight
          ? CrosscueColors.gridBorderLight
          : CrosscueColors.gridBorderDark,
      gridOuterBorder: isLight
          ? CrosscueColors.gridOuterBorderLight
          : CrosscueColors.gridOuterBorderDark,
      cellText: isLight
          ? CrosscueColors.onSurface1Light
          : CrosscueColors.onSurface1Dark,
      cellNumber: isLight
          ? CrosscueColors.gridClueNumberLight
          : CrosscueColors.gridClueNumberDark,
      focusedCellText: CrosscueColors.gridBlackLight,
      correctCellText: isLight
          ? CrosscueColors.gridCorrectLetterLight
          : CrosscueColors.gridCorrectLetterDark,
      correctFocusedCellText: isLight
          ? CrosscueColors.gridCorrectLetterLight
          : CrosscueColors.gridCorrectFocusedLetterDark,
      incorrectCellText: isLight
          ? CrosscueColors.gridWrongLetterLight
          : CrosscueColors.gridWrongLetterDark,
      colorblindCorrectCellText: isLight
          ? CrosscueColors.gridCbCorrectLetterLight
          : CrosscueColors.gridCbCorrectLetterDark,
      colorblindIncorrectCellText: isLight
          ? CrosscueColors.gridCbWrongLetterLight
          : CrosscueColors.gridCbWrongLetterDark,
      verificationUsesLetterColor: true,
      stateCorrect: isLight
          ? CrosscueColors.correctLight.withValues(alpha: 0.20)
          : CrosscueColors.correctDark.withValues(alpha: 0.20),
      stateIncorrect: isLight
          ? CrosscueColors.incorrectLight.withValues(alpha: 0.20)
          : CrosscueColors.incorrectDark.withValues(alpha: 0.20),
      stateRevealed:
          isLight ? CrosscueColors.revealedLight : CrosscueColors.revealedDark,
      clueBarBg: isLight
          ? CrosscueColors.primaryContLight
          : CrosscueColors.primaryContDark,
      clueBarBorder:
          isLight ? CrosscueColors.wordHLLight : CrosscueColors.wordHLDark,
      clueBarDirection:
          isLight ? CrosscueColors.primary : CrosscueColors.primaryLight,
      clueBarText: isLight
          ? CrosscueColors.onSurface1Light
          : CrosscueColors.onSurface1Dark,
      activeClueBg:
          isLight ? CrosscueColors.wordHLLight : CrosscueColors.wordHLDark,
      cluePanelCrossRowBg: isLight
          ? CrosscueColors.cluePanelCrossRowLight.withValues(alpha: 0.55)
          : CrosscueColors.cluePanelCrossRowDark.withValues(alpha: 0.35),
      keyboardBg:
          isLight ? CrosscueColors.keyboardBg : CrosscueColors.keyboardBgDark,
      keyDefault:
          isLight ? CrosscueColors.surfaceLight : CrosscueColors.keyDefaultDark,
      keySpecial:
          isLight ? CrosscueColors.keyDelete : CrosscueColors.keyDeleteDark,
      keyCheck: isLight ? CrosscueColors.primary : CrosscueColors.primaryLight,
    );
  }

  /// Convenience fallback for contexts that resolve the theme before it
  /// is wired (e.g. fallback in `extension<CrosswordTheme>() ?? ...`).
  static CrosswordTheme light() => CrosswordTheme.of(
        ColorScheme.fromSeed(
          seedColor: CrosscueColors.seed,
          brightness: Brightness.light,
        ),
      );

  // ── ThemeExtension overrides ───────────────────────────────────────────────

  @override
  CrosswordTheme copyWith({
    Color? cellActive,
    Color? wordHighlight,
    Color? gridBlack,
    Color? gridEmpty,
    Color? gridBorder,
    Color? gridOuterBorder,
    Color? cellText,
    Color? cellNumber,
    Color? focusedCellText,
    Color? correctCellText,
    Color? correctFocusedCellText,
    Color? incorrectCellText,
    Color? colorblindCorrectCellText,
    Color? colorblindIncorrectCellText,
    bool? verificationUsesLetterColor,
    Color? stateCorrect,
    Color? stateIncorrect,
    Color? stateRevealed,
    Color? clueBarBg,
    Color? clueBarBorder,
    Color? clueBarDirection,
    Color? clueBarText,
    Color? activeClueBg,
    Color? cluePanelCrossRowBg,
    Color? keyboardBg,
    Color? keyDefault,
    Color? keySpecial,
    Color? keyCheck,
  }) {
    return CrosswordTheme(
      cellActive: cellActive ?? this.cellActive,
      wordHighlight: wordHighlight ?? this.wordHighlight,
      gridBlack: gridBlack ?? this.gridBlack,
      gridEmpty: gridEmpty ?? this.gridEmpty,
      gridBorder: gridBorder ?? this.gridBorder,
      gridOuterBorder: gridOuterBorder ?? this.gridOuterBorder,
      cellText: cellText ?? this.cellText,
      cellNumber: cellNumber ?? this.cellNumber,
      focusedCellText: focusedCellText ?? this.focusedCellText,
      correctCellText: correctCellText ?? this.correctCellText,
      correctFocusedCellText:
          correctFocusedCellText ?? this.correctFocusedCellText,
      incorrectCellText: incorrectCellText ?? this.incorrectCellText,
      colorblindCorrectCellText:
          colorblindCorrectCellText ?? this.colorblindCorrectCellText,
      colorblindIncorrectCellText:
          colorblindIncorrectCellText ?? this.colorblindIncorrectCellText,
      verificationUsesLetterColor:
          verificationUsesLetterColor ?? this.verificationUsesLetterColor,
      stateCorrect: stateCorrect ?? this.stateCorrect,
      stateIncorrect: stateIncorrect ?? this.stateIncorrect,
      stateRevealed: stateRevealed ?? this.stateRevealed,
      clueBarBg: clueBarBg ?? this.clueBarBg,
      clueBarBorder: clueBarBorder ?? this.clueBarBorder,
      clueBarDirection: clueBarDirection ?? this.clueBarDirection,
      clueBarText: clueBarText ?? this.clueBarText,
      activeClueBg: activeClueBg ?? this.activeClueBg,
      cluePanelCrossRowBg: cluePanelCrossRowBg ?? this.cluePanelCrossRowBg,
      keyboardBg: keyboardBg ?? this.keyboardBg,
      keyDefault: keyDefault ?? this.keyDefault,
      keySpecial: keySpecial ?? this.keySpecial,
      keyCheck: keyCheck ?? this.keyCheck,
    );
  }

  @override
  CrosswordTheme lerp(CrosswordTheme? other, double t) {
    if (other is! CrosswordTheme) return this;
    return CrosswordTheme(
      cellActive: Color.lerp(cellActive, other.cellActive, t)!,
      wordHighlight: Color.lerp(wordHighlight, other.wordHighlight, t)!,
      gridBlack: Color.lerp(gridBlack, other.gridBlack, t)!,
      gridEmpty: Color.lerp(gridEmpty, other.gridEmpty, t)!,
      gridBorder: Color.lerp(gridBorder, other.gridBorder, t)!,
      gridOuterBorder: Color.lerp(gridOuterBorder, other.gridOuterBorder, t)!,
      cellText: Color.lerp(cellText, other.cellText, t)!,
      cellNumber: Color.lerp(cellNumber, other.cellNumber, t)!,
      focusedCellText: Color.lerp(focusedCellText, other.focusedCellText, t)!,
      correctCellText: Color.lerp(correctCellText, other.correctCellText, t)!,
      correctFocusedCellText: Color.lerp(
        correctFocusedCellText,
        other.correctFocusedCellText,
        t,
      )!,
      incorrectCellText: Color.lerp(
        incorrectCellText,
        other.incorrectCellText,
        t,
      )!,
      colorblindCorrectCellText: Color.lerp(
        colorblindCorrectCellText,
        other.colorblindCorrectCellText,
        t,
      )!,
      colorblindIncorrectCellText: Color.lerp(
        colorblindIncorrectCellText,
        other.colorblindIncorrectCellText,
        t,
      )!,
      verificationUsesLetterColor: t < 0.5
          ? verificationUsesLetterColor
          : other.verificationUsesLetterColor,
      stateCorrect: Color.lerp(stateCorrect, other.stateCorrect, t)!,
      stateIncorrect: Color.lerp(stateIncorrect, other.stateIncorrect, t)!,
      stateRevealed: Color.lerp(stateRevealed, other.stateRevealed, t)!,
      clueBarBg: Color.lerp(clueBarBg, other.clueBarBg, t)!,
      clueBarBorder: Color.lerp(clueBarBorder, other.clueBarBorder, t)!,
      clueBarDirection: Color.lerp(
        clueBarDirection,
        other.clueBarDirection,
        t,
      )!,
      clueBarText: Color.lerp(clueBarText, other.clueBarText, t)!,
      activeClueBg: Color.lerp(activeClueBg, other.activeClueBg, t)!,
      cluePanelCrossRowBg:
          Color.lerp(cluePanelCrossRowBg, other.cluePanelCrossRowBg, t)!,
      keyboardBg: Color.lerp(keyboardBg, other.keyboardBg, t)!,
      keyDefault: Color.lerp(keyDefault, other.keyDefault, t)!,
      keySpecial: Color.lerp(keySpecial, other.keySpecial, t)!,
      keyCheck: Color.lerp(keyCheck, other.keyCheck, t)!,
    );
  }
}

/// Convenience extension — read CrosswordTheme from any [BuildContext].
extension CrosswordThemeX on BuildContext {
  CrosswordTheme get cw => Theme.of(this).extension<CrosswordTheme>()!;
}
