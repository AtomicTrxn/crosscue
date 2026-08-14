import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Row height for a clue-list row: enough to fit the TALLEST of [texts] at
/// [textWidth] under the CURRENT text scaler, plus the row's 16px (8+8)
/// vertical padding — never less than the original fixed 56px design
/// height. Every row in the list shares one uniform extent (see the
/// scroll-offset math in clue_list_panel.dart / clue_columns_panel.dart),
/// so it must fit the single longest clue, not an assumed line count —
/// clue text must never be truncated, at any text scale or clue length.
double clueRowExtent(
  BuildContext context, {
  required Iterable<String> texts,
  required double textWidth,
}) {
  const minExtent = 56.0;
  const verticalPadding = 16.0;
  final scaler = MediaQuery.textScalerOf(context);
  var maxHeight = 0.0;
  for (final text in texts) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        // w600 (the active-row weight) as a conservative upper bound —
        // bold glyphs are never narrower than regular, so this never
        // under-measures a row that becomes active.
        style: const TextStyle(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: textWidth);
    if (tp.height > maxHeight) maxHeight = tp.height;
  }
  return math.max(minExtent, verticalPadding + maxHeight);
}
