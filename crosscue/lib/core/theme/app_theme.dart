// Crosscue app theme — light + dark ThemeData seeded from Crosscue brand blue.
// Use with dynamic_color package for Material You on Android 12+.

import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

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
      scaffoldBackgroundColor:
          isLight ? CrosscueColors.bgLight : CrosscueColors.bgDark,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        // 1px bottom border on every AppBar
        shape: Border(
          bottom: BorderSide(
            color: isLight
                ? CrosscueColors.dividerLight
                : CrosscueColors.dividerDark,
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
        color:
            isLight ? CrosscueColors.dividerLight : CrosscueColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      dividerColor:
          isLight ? CrosscueColors.dividerLight : CrosscueColors.dividerDark,

      // ── Dialogs (v3.5) ──────────────────────────────────────────────────────
      // Centralised scrim (barrier) and surface so every AlertDialog/showDialog
      // call site picks up the guide values without per-call overrides.
      dialogTheme: DialogThemeData(
        backgroundColor: isLight
            ? CrosscueColors.dialogSurfaceLight
            : CrosscueColors.dialogSurfaceDark,
        surfaceTintColor: Colors.transparent,
        barrierColor: isLight
            ? CrosscueColors.dialogScrimLight
            : CrosscueColors.dialogScrimDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Filled buttons ──────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isLight
              ? CrosscueColors.buttonDisabledBgLight
              : CrosscueColors.buttonDisabledBgDark,
          disabledForegroundColor: isLight
              ? CrosscueColors.buttonDisabledTextLight
              : CrosscueColors.buttonDisabledTextDark,
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
      // v3.5: border uses the toggleTrackOff token (not divider colors).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          disabledForegroundColor: isLight
              ? CrosscueColors.buttonDisabledTextLight
              : CrosscueColors.buttonDisabledTextDark,
          side: BorderSide(
            color: isLight
                ? CrosscueColors.toggleTrackOffLight
                : CrosscueColors.toggleTrackOffDark,
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
      // v3.5 default is the "dismiss" semantic = onSurface2. Action/link buttons
      // (primary) and destructive buttons override per-call.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isLight
              ? CrosscueColors.onSurface2Light
              : CrosscueColors.onSurface2Dark,
          textStyle: const TextStyle(
            fontFamily: CrosscueTypography.roboto,
            fontSize: CrosscueTypography.bodySmall,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // ── Switches (v3.5) ─────────────────────────────────────────────────────
      // Off-state track uses the dedicated toggleTrackOff guide token. On-state
      // track uses primary. Thumb is white in both states for legibility.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return isLight
                ? CrosscueColors.buttonDisabledTextLight
                : CrosscueColors.buttonDisabledTextDark;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return isLight
              ? CrosscueColors.toggleTrackOffLight
              : CrosscueColors.toggleTrackOffDark;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // ── Segmented buttons (v3.5) ────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isLight
                  ? CrosscueColors.primaryContLight
                  : CrosscueColors.primaryContDark;
            }
            return isLight
                ? CrosscueColors.segmentedControlBgLight
                : CrosscueColors.segmentedControlBgDark;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return isLight
                ? CrosscueColors.onSurface2Light
                : CrosscueColors.onSurface2Dark;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: isLight
                  ? CrosscueColors.toggleTrackOffLight
                  : CrosscueColors.toggleTrackOffDark,
            ),
          ),
        ),
      ),

      // ── Filter chips (v3.5) ─────────────────────────────────────────────────
      // Unselected: surface bg, toggleTrackOff border, onSurface3 label.
      // Selected:   primaryContainer bg, wordHighlight border, primary label.
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
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
        secondaryLabelStyle: TextStyle(
          fontFamily: CrosscueTypography.roboto,
          fontSize: CrosscueTypography.bodySmall,
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CrosscueSpacing.chipRadius),
          side: BorderSide(
            color: isLight
                ? CrosscueColors.toggleTrackOffLight
                : CrosscueColors.toggleTrackOffDark,
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
