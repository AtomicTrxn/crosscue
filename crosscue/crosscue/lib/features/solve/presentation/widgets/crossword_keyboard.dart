import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/crossword_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// Custom QWERTY keyboard for the solve screen (Sprint 10).
///
/// Design spec:
/// - Background: #ECEFF1 (keyboardBg)
/// - Padding: 6dp top, 4dp horizontal, 8dp bottom
/// - Row gap: 4dp between rows, 3dp between keys
/// - Standard key: height 36dp, flex 1, maxWidth 32dp, white bg, 5dp radius,
///   12px w500 #1A1A1A, shadow 0 1px 1px rgba(0,0,0,0.15)
/// - ⌫ key: 38dp wide, #B0BEC5 bg, white text
/// - ✓ key (Check Word): 38dp wide, #1565C0 bg, white text
/// - Three rows: QWERTYUIOP / ASDFGHJKL / ⌫ZXCVBNM✓
///
/// Physical keyboard input is still handled via the hidden [TextField] in
/// [CrosswordGrid]; this widget handles soft-keyboard input only.
class CrosswordKeyboard extends StatelessWidget {
  const CrosswordKeyboard({
    super.key,
    required this.onLetter,
    required this.onBackspace,
    required this.onCheckWord,
    this.hapticsEnabled = true,
  });

  final void Function(String letter) onLetter;
  final VoidCallback onBackspace;
  final VoidCallback onCheckWord;
  final bool hapticsEnabled;

  static const _row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  static const _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  static const _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  Widget build(BuildContext context) {
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();

    return Container(
      color: xwTheme.keyboardBg,
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _KeyRow(
            keys: _row1,
            onLetter: _tap,
            xwTheme: xwTheme,
          ),
          const SizedBox(height: 4),
          _KeyRow(
            keys: _row2,
            onLetter: _tap,
            xwTheme: xwTheme,
          ),
          const SizedBox(height: 4),
          // Bottom row: ⌫ + letters + ✓
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Backspace
              _SpecialKey(
                label: '⌫',
                color: xwTheme.keySpecial,
                textColor: Colors.white,
                onTap: () {
                  if (hapticsEnabled) HapticFeedback.selectionClick();
                  onBackspace();
                },
              ),
              const SizedBox(width: 3),
              // Letter keys
              ..._row3.map((l) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: _LetterKey(
                      letter: l,
                      onTap: () => _tap(l),
                      xwTheme: xwTheme,
                    ),
                  )),
              // Check-word key
              _SpecialKey(
                label: '✓',
                color: xwTheme.keyCheck,
                textColor: Colors.white,
                onTap: () {
                  if (hapticsEnabled) HapticFeedback.lightImpact();
                  onCheckWord();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _tap(String letter) {
    if (hapticsEnabled) HapticFeedback.lightImpact();
    onLetter(letter);
  }
}

// ---------------------------------------------------------------------------
// Key row
// ---------------------------------------------------------------------------

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.keys,
    required this.onLetter,
    required this.xwTheme,
  });

  final List<String> keys;
  final void Function(String) onLetter;
  final CrosswordTheme xwTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          _LetterKey(
            letter: keys[i],
            onTap: () => onLetter(keys[i]),
            xwTheme: xwTheme,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Standard letter key
// ---------------------------------------------------------------------------

class _LetterKey extends StatelessWidget {
  const _LetterKey({
    required this.letter,
    required this.onTap,
    required this.xwTheme,
  });

  final String letter;
  final VoidCallback onTap;
  final CrosswordTheme xwTheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 32),
        height: 36,
        // Use flex-like sizing: fill available width up to maxWidth
        width: double.infinity,
        decoration: BoxDecoration(
          color: xwTheme.keyDefault,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000), // rgba(0,0,0,0.15)
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CrosscueColors.onSurface1Light,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Special key (⌫ / ✓)
// ---------------------------------------------------------------------------

class _SpecialKey extends StatelessWidget {
  const _SpecialKey({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1,
          ),
        ),
      ),
    );
  }
}
