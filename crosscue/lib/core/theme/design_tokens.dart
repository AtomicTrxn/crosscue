// design_tokens.dart
// Crosscue design token system — colors, typography, spacing.
// Widgets should consume these via [CrosswordTheme] or [ColorScheme] extensions,
// not reference [CrosscueColors] directly.

import 'package:flutter/material.dart';

/// All raw color values used across the app.
abstract class CrosscueColors {
  // ── Primary palette ────────────────────────────────────────────────────────
  // Brand blue. Use Color.lerp / withValues when a darker/lighter shade is
  // needed; we don't keep separate "primaryMid"/"primaryDark" tokens.
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF7EB8F7); // dark-mode primary
  static const Color deepNavy = Color(0xFF0A2A6E); // navy used for onPrimary

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF111318);
  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color bgDark = Color(0xFF181B22);

  // ── Neutral ramp ───────────────────────────────────────────────────────────
  // Aligned to the Tailwind gray scale so on-surface text, dividers, and
  // illustration neutrals all draw from one consistent ramp.
  static const Color onSurface1Light = Color(0xFF1A1A1A); // gray-900 (≈)
  static const Color onSurface2Light = Color(0xFF6B7280); // gray-500
  static const Color onSurface3Light = Color(0xFF9CA3AF); // gray-400

  static const Color onSurface1Dark = Color(0xFFE4EAF8);
  static const Color onSurface2Dark = Color(0xFF8892AC);
  static const Color onSurface3Dark = Color(0xFF5C6E96);

  // ── Dividers ───────────────────────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFE5E7EB); // gray-200
  static const Color dividerDark = Color(0xFF232840);

  // ── Grid cell states ───────────────────────────────────────────────────────
  static const Color cellActiveLight = Color(0xFFFDD835); // focused cell
  static const Color cellActiveDark = Color(0xFFF5B700);

  static const Color wordHLLight = Color(0xFFBBDEFB); // active word
  static const Color wordHLDark = Color(0xFF1C3D78);

  static const Color crossHLLight = Color(0xFFE3F2FD); // crossing word
  static const Color crossHLDark = Color(0xFF0D2248);

  static const Color gridBlackLight = Color(0xFF111111); // blocked squares
  static const Color gridBlackDark = Color(0xFF060810);

  static const Color gridBorderLight = Color(0xFFBDBDBD);
  static const Color gridBorderDark = Color(0xFF2A3148);
  static const Color gridOuterBorderLight = Color(0xFFB0B0B0);
  static const Color gridOuterBorderDark = Color(0xFF3A4464);

  static const Color gridEmptyLight = Color(0xFFFFFFFF);
  static const Color gridEmptyDark = Color(0xFF1E2535);
  static const Color gridClueNumberLight = Color(0xFF6B7280);
  static const Color gridClueNumberDark = Color(0xFF5C6E96);
  static const Color gridCorrectLetterLight = Color(0xFF166534);
  static const Color gridWrongLetterLight = Color(0xFF9B1C1C);
  static const Color gridCbCorrectLetterLight = Color(0xFF1D4ED8);
  static const Color gridCbWrongLetterLight = Color(0xFFB45309);
  static const Color gridCorrectLetterDark = Color(0xFF34D399);
  static const Color gridCorrectFocusedLetterDark = Color(0xFF1A6B3A);
  static const Color gridWrongLetterDark = Color(0xFFF87171);
  static const Color gridCbCorrectLetterDark = Color(0xFF60A5FA);
  static const Color gridCbWrongLetterDark = Color(0xFFFB923C);

  // ── State colors ───────────────────────────────────────────────────────────
  // One success green, one warning red. Apply at 20% opacity for cell-level
  // feedback overlays; at full opacity for destructive UI / labels.
  static const Color correctLight = Color(0xFF4CAF50);
  static const Color correctDark = Color(0xFF66BB6A);

  // Muted brick red — paired with brand blue across all error / destructive
  // surfaces (grid-incorrect overlays, "Delete" labels, confirmation buttons).
  static const Color incorrectLight = Color(0xFFB85450);
  static const Color incorrectDark = Color(0xFFE89691);

  static const Color revealedLight = Color(0xFFFFF9C4);
  static const Color revealedDark = Color(0xFFFFB74D);

  // ── Completion state ───────────────────────────────────────────────────────
  static const Color completedCellBg = Color(0xFFC8E6C9); // light green fill
  static const Color completedCellFg = Color(0xFF2E7D32); // dark green letter

  // ── Overlay & misc ─────────────────────────────────────────────────────────
  static const Color barrierDeepNavy = Color(0xE10A2A6E); // 88% alpha deep navy
  static const Color trackGrey = Color(
    0xFFE0E0E0,
  ); // pie chart / progress track

  // ── Confetti palette ───────────────────────────────────────────────────────
  // Mirrors the four semantic colors (brand, accent, success, warning) so the
  // celebration animation uses the same vocabulary as the rest of the UI.
  static const List<Color> confettiPalette = [
    primary,
    cellActiveLight,
    correctLight,
    incorrectLight,
  ];

  // ── Containers ─────────────────────────────────────────────────────────────
  static const Color primaryContLight = Color(0xFFE3F2FD);
  static const Color primaryContDark = Color(0x331B3E82); // 20% opacity

  // ── Keyboard ───────────────────────────────────────────────────────────────
  static const Color keyboardBg = Color(0xFFECEFF1);
  static const Color keyboardBgDark = Color(0xFF161A28);
  static const Color keyDefault = Color(0xFFFFFFFF);
  static const Color keyDefaultDark = Color(0xFF232A3C);
  static const Color keyDelete = Color(0xFFB0BEC5);
  static const Color keyDeleteDark = Color(0xFF2E3448);

  // ── Seed color for Material You ────────────────────────────────────────────
  static const Color seed = Color(0xFF2196F3);
}

/// Typography constants.
abstract class CrosscueTypography {
  static const String roboto = 'Roboto';
  static const String robotoMono = 'RobotoMono';

  // Font sizes
  static const double screenTitle = 20.0; // AppBar title
  static const double puzzleTitle = 18.0;
  static const double body = 14.0;
  static const double bodySmall = 13.0;
  static const double label = 12.0;
  static const double labelSmall = 11.0;
  static const double labelXSmall = 10.0;

  static const double timer = 14.0;
  static const double timerLarge = 52.0; // completion sheet

  // Clue bar
  static const double clueBarDirection = 12.0;
  static const double clueBarText = 13.0;

  // Grid — computed at runtime: cellSize * factor
  static const double cellLetterFactor = 0.52;
  static const double cellNumberFactor = 0.22;
}

/// Spacing constants.
abstract class CrosscueSpacing {
  static const double screenH = 16.0; // horizontal screen padding
  static const double rowV = 13.0; // vertical list row padding
  static const double sectionTop = 16.0;
  static const double sectionBot = 6.0;

  static const double appBarHeight = 56.0;
  static const double appBarHeightSolve = 48.0;
  static const double bottomNavHeight = 60.0;
  static const double clueBarV = 9.0;
  static const double clueBarH = 12.0;

  static const double fabSize = 52.0;
  static const double fabRadius = 16.0;
  static const double fabBottom = 76.0;
  static const double fabRight = 16.0;

  static const double buttonRadius = 8.0;
  static const double buttonRadiusLg = 10.0;
  static const double chipRadius = 20.0;

  static const double toggleW = 44.0;
  static const double toggleH = 24.0;
  static const double toggleThumb = 20.0;

  static const double sheetRadius = 20.0;
  static const double dragHandleW = 36.0;
  static const double dragHandleH = 4.0;
}
