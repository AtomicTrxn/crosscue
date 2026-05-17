import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

extension CrosscueThemeColors on BuildContext {
  bool get isCrosscueLight => Theme.of(this).brightness == Brightness.light;

  Color get crosscueOnSurface1 => isCrosscueLight
      ? CrosscueColors.onSurface1Light
      : CrosscueColors.onSurface1Dark;

  Color get crosscueSurface => isCrosscueLight
      ? CrosscueColors.surfaceLight
      : CrosscueColors.surfaceDark;

  Color get crosscuePrimary =>
      isCrosscueLight ? CrosscueColors.primary : CrosscueColors.primaryLight;

  Color get crosscueOnSurface2 => isCrosscueLight
      ? CrosscueColors.onSurface2Light
      : CrosscueColors.onSurface2Dark;

  Color get crosscueOnSurface3 => isCrosscueLight
      ? CrosscueColors.onSurface3Light
      : CrosscueColors.onSurface3Dark;

  Color get crosscueDivider => isCrosscueLight
      ? CrosscueColors.dividerLight
      : CrosscueColors.dividerDark;

  Color get crosscuePrimaryContainer => isCrosscueLight
      ? CrosscueColors.primaryContLight
      : CrosscueColors.primaryContDark;

  Color get crosscueWordHighlight =>
      isCrosscueLight ? CrosscueColors.wordHLLight : CrosscueColors.wordHLDark;

  Color get crosscueCorrect => isCrosscueLight
      ? CrosscueColors.correctLight
      : CrosscueColors.correctDark;

  Color get crosscueError => isCrosscueLight
      ? CrosscueColors.incorrectLight
      : CrosscueColors.incorrectDark;

  /// Destructive-action color (Delete buttons, Clear all data, etc.).
  /// Use this instead of [crosscueError] for buttons/labels that *perform* a
  /// destructive operation. [crosscueError] remains for error semantics only.
  Color get crosscueActionDestructive => isCrosscueLight
      ? CrosscueColors.actionDestructiveLight
      : CrosscueColors.actionDestructiveDark;

  /// Off-state toggle/segmented-control track color. Also the v3.5 outlined-
  /// button border color.
  Color get crosscueToggleTrackOff => isCrosscueLight
      ? CrosscueColors.toggleTrackOffLight
      : CrosscueColors.toggleTrackOffDark;
}
