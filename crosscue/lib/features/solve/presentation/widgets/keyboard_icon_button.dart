import 'dart:math' as math;

import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Small primary-blue icon button used by the floating [KeyboardHiddenControls]
/// cluster (#298) — same visual language as the app's branded FAB (primary +
/// [CrosscueSpacing.fabRadius], see the Color Guide), just at mini-FAB scale.
class KeyboardIconButton extends StatelessWidget {
  const KeyboardIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.rotate180 = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Flips [icon] upside down — used for "show keyboard" so it's a
  /// deterministic 180° rotation of [Icons.keyboard_hide] (keyboard base +
  /// down-chevron) rather than a different named icon whose actual glyph
  /// can't be visually verified ahead of time (`Icons.keyboard_control`
  /// turned out to render as an unrelated "•••" glyph in this Flutter
  /// version's bundled font, not the keyboard+up-chevron its name implies).
  /// Rotating the already-confirmed glyph 180° reliably turns the
  /// down-chevron into an up-chevron above the keyboard base.
  final bool rotate180;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 20);
    return FloatingActionButton.small(
      heroTag: null,
      tooltip: tooltip,
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrosscueSpacing.fabRadius),
      ),
      child: rotate180
          ? Transform.rotate(angle: math.pi, child: iconWidget)
          : iconWidget,
    );
  }
}
