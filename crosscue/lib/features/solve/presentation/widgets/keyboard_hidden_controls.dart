import 'package:crosscue/features/solve/presentation/widgets/keyboard_icon_button.dart';
import 'package:flutter/material.dart';

/// Floating control cluster shown when the on-screen keyboard is hidden
/// (#298). Replaces the old settings-screen toggle + app-bar escape hatch
/// with an always-in-context way back to the keyboard, plus the actions
/// that would otherwise become unreachable without it:
///
///  - **Rebus** — the on-screen keyboard's Rebus key has no other touch
///    equivalent once the tray is hidden (the Esc-key shortcut and the
///    grid's long-press menu both still work, but this keeps a one-tap path
///    for touch-only moments).
///  - **Show keyboard** — brings the [CrosswordKeyboard] tray back.
///
/// Laid out horizontally, Rebus-then-Show, and anchored in
/// `solve_screen.dart` to the same corner offsets as the keyboard's own
/// Rebus/hide-keyboard keys (rightmost two keys of its bottom row) so the
/// two controls land in essentially the same screen position whichever
/// state the keyboard is in — hiding/showing the keyboard reads as those
/// two buttons staying put while the QWERTY rows collapse/expand around
/// them, not as controls jumping to a different corner.
class KeyboardHiddenControls extends StatelessWidget {
  const KeyboardHiddenControls({
    super.key,
    required this.onShowKeyboard,
    required this.onRebus,
  });

  final VoidCallback onShowKeyboard;
  final VoidCallback onRebus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeyboardIconButton(
          icon: Icons.edit_note,
          tooltip: 'Enter rebus',
          onTap: onRebus,
        ),
        const SizedBox(width: 8),
        KeyboardIconButton(
          icon: Icons.keyboard_hide,
          tooltip: 'Show keyboard',
          onTap: onShowKeyboard,
          rotate180: true,
        ),
      ],
    );
  }
}
