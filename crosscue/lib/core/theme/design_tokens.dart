// design_tokens.dart
// Crosscue design token system — colors, typography, spacing.
// Widgets should consume these via [CrosswordTheme] or [ColorScheme] extensions,
// not reference [CrosscueColors] directly.

import 'package:flutter/material.dart';

/// All raw color values used across the app.
abstract class CrosscueColors {
  // ── Primary palette ────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF1565C0);
  static const Color primaryMid    = Color(0xFF1E88E5);
  static const Color primaryDark   = Color(0xFF0D47A1);
  static const Color deepNavy      = Color(0xFF0A2A6E);
  static const Color primaryLight  = Color(0xFF90CAF9);  // dark mode primary

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color surfaceLight  = Color(0xFFFFFFFF);
  static const Color surfaceDark   = Color(0xFF121212);
  static const Color bgLight       = Color(0xFFFAFAFA);
  static const Color bgDark        = Color(0xFF1A1A1A);

  // ── On-surface text ────────────────────────────────────────────────────────
  static const Color onSurface1Light = Color(0xFF1A1A1A);
  static const Color onSurface2Light = Color(0xFF555555);
  static const Color onSurface3Light = Color(0xFF999999);

  static const Color onSurface1Dark  = Color(0xFFE0E0E0);
  static const Color onSurface2Dark  = Color(0xFF9E9E9E);
  static const Color onSurface3Dark  = Color(0xFF616161);

  // ── Dividers ───────────────────────────────────────────────────────────────
  static const Color dividerLight  = Color(0xFFE8E8E8);
  static const Color dividerDark   = Color(0xFF2C2C2C);

  // ── Grid cell states ───────────────────────────────────────────────────────
  static const Color cellActiveLight  = Color(0xFFFDD835);  // focused cell
  static const Color cellActiveDark   = Color(0xFFFFD54F);

  static const Color wordHLLight      = Color(0xFFBBDEFB);  // active word
  static const Color wordHLDark       = Color(0xFF1565C0);

  static const Color crossHLLight     = Color(0xFFE3F2FD);  // crossing word
  static const Color crossHLDark      = Color(0xFF0D47A1);

  static const Color gridBlackLight   = Color(0xFF111111);  // blocked squares
  static const Color gridBlackDark    = Color(0xFF1A1A1A);

  static const Color gridBorderLight  = Color(0xFFBDBDBD);
  static const Color gridBorderDark   = Color(0xFF424242);

  static const Color gridEmptyLight   = Color(0xFFFFFFFF);
  static const Color gridEmptyDark    = Color(0xFF1E1E1E);

  // ── State colors ───────────────────────────────────────────────────────────
  static const Color correctLight    = Color(0xFF4CAF50);
  static const Color correctDark     = Color(0xFF66BB6A);

  static const Color incorrectLight  = Color(0xFFEF5350);
  static const Color incorrectDark   = Color(0xFFEF9A9A);

  static const Color revealedLight   = Color(0xFFFFF9C4);
  static const Color revealedDark    = Color(0xFFFFB74D);

  // ── Containers ─────────────────────────────────────────────────────────────
  static const Color primaryContLight = Color(0xFFE3F2FD);
  static const Color primaryContDark  = Color(0x201565C0);  // 12% opacity

  // ── Keyboard ───────────────────────────────────────────────────────────────
  static const Color keyboardBg      = Color(0xFFECEFF1);
  static const Color keyDefault      = Color(0xFFFFFFFF);
  static const Color keyDelete       = Color(0xFFB0BEC5);

  // ── Seed color for Material You ────────────────────────────────────────────
  static const Color seed = Color(0xFF2196F3);
}

/// Typography constants.
abstract class CrosscueTypography {
  static const String roboto      = 'Roboto';
  static const String robotoMono  = 'RobotoMono';

  // Font sizes
  static const double screenTitle  = 20.0;  // AppBar title
  static const double puzzleTitle  = 18.0;
  static const double body         = 14.0;
  static const double bodySmall    = 13.0;
  static const double label        = 12.0;
  static const double labelSmall   = 11.0;
  static const double labelXSmall  = 10.0;

  static const double timer        = 14.0;
  static const double timerLarge   = 52.0;  // completion sheet

  // Clue bar
  static const double clueBarDirection = 12.0;
  static const double clueBarText      = 13.0;

  // Grid — computed at runtime: cellSize * factor
  static const double cellLetterFactor = 0.52;
  static const double cellNumberFactor = 0.22;
}

/// Spacing constants.
abstract class CrosscueSpacing {
  static const double screenH      = 16.0;  // horizontal screen padding
  static const double rowV         = 13.0;  // vertical list row padding
  static const double sectionTop   = 16.0;
  static const double sectionBot   =  6.0;

  static const double appBarHeight      = 56.0;
  static const double appBarHeightSolve = 48.0;
  static const double bottomNavHeight   = 60.0;
  static const double clueBarV          =  9.0;
  static const double clueBarH          = 12.0;

  static const double fabSize         = 52.0;
  static const double fabRadius       = 16.0;
  static const double fabBottom       = 76.0;
  static const double fabRight        = 16.0;

  static const double buttonRadius    =  8.0;
  static const double buttonRadiusLg  = 10.0;
  static const double chipRadius      = 20.0;

  static const double toggleW         = 44.0;
  static const double toggleH         = 24.0;
  static const double toggleThumb     = 20.0;

  static const double sheetRadius     = 20.0;
  static const double dragHandleW     = 36.0;
  static const double dragHandleH     =  4.0;
}
