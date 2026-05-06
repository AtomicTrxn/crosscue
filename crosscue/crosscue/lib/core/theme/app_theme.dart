// Crosscue app theme — light + dark ThemeData seeded from Crosscue brand blue.
// Use with dynamic_color package for Material You on Android 12+.

import 'package:flutter/material.dart';

import 'crossword_theme.dart';
import 'design_tokens.dart';

abstract final class AppTheme {
  /// Light theme — fallback when dynamic color is unavailable.
  static ThemeData light({ColorScheme? dynamicScheme}) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: CrosscueColors.seed,
          brightness: Brightness.light,
        ).copyWith(
          primary: CrosscueColors.primary,
          onPrimary: Colors.white,
          primaryContainer: CrosscueColors.primaryContLight,
          surface: CrosscueColors.surfaceLight,
          onSurface: CrosscueColors.onSurface1Light,
          error: CrosscueColors.incorrectLight,
        );
    return _build(scheme);
  }

  /// Dark theme — fallback when dynamic color is unavailable.
  static ThemeData dark({ColorScheme? dynamicScheme}) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: CrosscueColors.seed,
          brightness: Brightness.dark,
        ).copyWith(
          primary: CrosscueColors.primaryLight,
          onPrimary: CrosscueColors.deepNavy,
          primaryContainer: CrosscueColors.primaryContDark,
          surface: CrosscueColors.surfaceDark,
          onSurface: CrosscueColors.onSurface1Dark,
          error: CrosscueColors.incorrectDark,
        );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        // 1px bottom border on every AppBar (spec §01–06)
        shape: Border(
          bottom: BorderSide(
            color: isLight ? CrosscueColors.dividerLight : CrosscueColors.dividerDark,
            width: 1,
          ),
        ),
        titleTextStyle: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.screenTitle,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),

      // ── Bottom Navigation Bar ───────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: CrosscueTypography.roboto,
            fontSize: CrosscueTypography.labelSmall,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active
                ? scheme.primary
                : (isLight
                    ? CrosscueColors.onSurface3Light
                    : CrosscueColors.onSurface3Dark),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active
                ? scheme.primary
                : (isLight
                    ? CrosscueColors.onSurface3Light
                    : CrosscueColors.onSurface3Dark),
            size: 24,
          );
        }),
        height: CrosscueSpacing.bottomNavHeight,
      ),

      // ── Dividers ────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isLight ? CrosscueColors.dividerLight : CrosscueColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      dividerColor:
          isLight ? CrosscueColors.dividerLight : CrosscueColors.dividerDark,

      // ── Filled buttons ──────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: CrosscueTypography.roboto,
            fontSize: CrosscueTypography.body,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadius),
          ),
          minimumSize: const Size.fromHeight(46),
        ),
      ),

      // ── Outlined buttons ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(
            color: isLight
                ? CrosscueColors.dividerLight
                : CrosscueColors.dividerDark,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: CrosscueTypography.roboto,
            fontSize: CrosscueTypography.body,
            fontWeight: FontWeight.w500,
          ),
          minimumSize: const Size.fromHeight(46),
        ),
      ),

      // ── Text buttons ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isLight
              ? CrosscueColors.onSurface3Light
              : CrosscueColors.onSurface3Dark,
          textStyle: const TextStyle(
            fontFamily: CrosscueTypography.roboto,
            fontSize: CrosscueTypography.bodySmall,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // ── Filter chips ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: isLight
            ? CrosscueColors.primaryContLight
            : CrosscueColors.primaryContDark,
        labelStyle: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.bodySmall,
          fontWeight: FontWeight.w400,
          color: isLight
              ? CrosscueColors.onSurface3Light
              : CrosscueColors.onSurface3Dark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CrosscueSpacing.chipRadius),
          side: BorderSide(
            color: isLight
                ? CrosscueColors.dividerLight
                : CrosscueColors.dividerDark,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        elevation: 0,
        pressElevation: 0,
      ),

      // ── List tiles ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CrosscueSpacing.screenH,
          vertical: CrosscueSpacing.rowV,
        ),
        titleTextStyle: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.body + 1,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.label,
          color: isLight
              ? CrosscueColors.onSurface3Light
              : CrosscueColors.onSurface3Dark,
        ),
      ),

      // ── Cards ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isLight
                ? CrosscueColors.dividerLight
                : CrosscueColors.dividerDark,
          ),
        ),
      ),

      // ── Text theme ──────────────────────────────────────────────────────────
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.screenTitle,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.puzzleTitle,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.body,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.bodySmall,
          color: isLight
              ? CrosscueColors.onSurface2Light
              : CrosscueColors.onSurface2Dark,
        ),
        labelLarge: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.label,
          fontWeight: FontWeight.w500,
          color: isLight
              ? CrosscueColors.onSurface2Light
              : CrosscueColors.onSurface2Dark,
        ),
        labelMedium: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.labelSmall,
          fontWeight: FontWeight.w600,
          color: isLight
              ? CrosscueColors.onSurface3Light
              : CrosscueColors.onSurface3Dark,
          letterSpacing: 0.08,
        ),
        labelSmall: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.labelXSmall,
          fontWeight: FontWeight.w600,
          color: isLight
              ? CrosscueColors.onSurface3Light
              : CrosscueColors.onSurface3Dark,
        ),
      ),

      // ── Extensions ──────────────────────────────────────────────────────────
      extensions: [
        CrosswordTheme.of(scheme),
      ],
    );
  }
}

/// Timer text styles — available on any [BuildContext].
extension TimerStyle on BuildContext {
  TextStyle get timerStyle => const TextStyle(
        fontFamily: CrosscueTypography.robotoMono,
        fontSize: CrosscueTypography.timer,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      );

  TextStyle get completionTimerStyle => const TextStyle(
        fontFamily: CrosscueTypography.robotoMono,
        fontSize: CrosscueTypography.timerLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: -2,
      );
}
