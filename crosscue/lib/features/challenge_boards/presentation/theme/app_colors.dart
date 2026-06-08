import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:flutter/material.dart';

/// Challenge UI color adapter.
///
/// The design handoff uses an `AppColors` facade; this adapter keeps those
/// widgets mapped onto Crosscue's existing token system instead of introducing
/// another palette.
abstract final class AppColors {
  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surface(BuildContext context) => context.crosscueSurface;

  static Color divider(BuildContext context) => context.crosscueDivider;

  static Color onSurface1(BuildContext context) => context.crosscueOnSurface1;

  static Color onSurface2(BuildContext context) => context.crosscueOnSurface2;

  static Color onSurface3(BuildContext context) => context.crosscueOnSurface3;

  static Color primary(BuildContext context) => context.crosscuePrimary;

  static Color primaryContainer(BuildContext context) =>
      context.crosscuePrimaryContainer;

  static Color correct(BuildContext context) => context.crosscueCorrect;

  static Color incorrect(BuildContext context) => context.crosscueError;

  static Color actionDestructive(BuildContext context) =>
      context.crosscueActionDestructive;

  static Color segmentedControlBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? CrosscueColors.segmentedControlBgDark
          : CrosscueColors.segmentedControlBgLight;

  static Color dialogSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? CrosscueColors.dialogSurfaceDark
          : CrosscueColors.dialogSurfaceLight;

  static Color dialogScrim(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? CrosscueColors.dialogScrimDark
          : CrosscueColors.dialogScrimLight;

  static Color buttonDisabledBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? CrosscueColors.buttonDisabledBgDark
          : CrosscueColors.buttonDisabledBgLight;

  static Color buttonDisabledText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? CrosscueColors.buttonDisabledTextDark
          : CrosscueColors.buttonDisabledTextLight;

  static const Color streakAccent = CrosscueColors.cellActiveLight;
  static const Color progressTrack = CrosscueColors.trackGrey;
}
