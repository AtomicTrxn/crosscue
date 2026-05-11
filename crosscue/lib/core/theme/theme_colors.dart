import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

extension CrosscueThemeColors on BuildContext {
  bool get isCrosscueLight => Theme.of(this).brightness == Brightness.light;

  Color get crosscueOnSurface1 => isCrosscueLight
      ? CrosscueColors.onSurface1Light
      : CrosscueColors.onSurface1Dark;

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
}
