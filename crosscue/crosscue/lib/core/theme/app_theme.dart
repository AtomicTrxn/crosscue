import 'package:flutter/material.dart';

import 'crossword_theme.dart';

/// Seed color for the app. Used when Material You dynamic color is unavailable.
const _kSeedColor = Color(0xFF1565C0); // Blue 800

/// Builds the full app [ThemeData] for light or dark mode.
///
/// Pass a [dynamicScheme] from `dynamic_color` when Material You is available
/// on Android 12+; otherwise the fixed [_kSeedColor] seed is used.
abstract final class AppTheme {
  static ThemeData light({ColorScheme? dynamicScheme}) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: _kSeedColor,
          brightness: Brightness.light,
        );
    return _build(scheme, CrosswordTheme.light());
  }

  static ThemeData dark({ColorScheme? dynamicScheme}) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: _kSeedColor,
          brightness: Brightness.dark,
        );
    return _build(scheme, CrosswordTheme.dark());
  }

  static ThemeData _build(ColorScheme scheme, CrosswordTheme xwTheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [xwTheme],

      // Roboto Mono used for grid cells via explicit TextStyle in painters.
      // Body text stays with Roboto (Material default).
      fontFamily: 'Roboto',

      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),

      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: scheme.secondaryContainer,
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
