import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom QWERTY keyboard for the solve screen (Sprint 10).
///
/// Design spec:
/// - Background: #ECEFF1 (keyboardBg)
/// - Padding: 6dp top, 4dp horizontal, 8dp bottom
/// - Row gap: 4dp between rows, 3dp between keys
/// - Standard key: height 50dp, responsive width fills available space, white bg,
///   5dp radius, 16px w500 #1A1A1A, shadow 0 1px 1px rgba(0,0,0,0.15)
/// - Small puzzles: height 54dp, 17px text
/// - ⌫ / ✓ keys: responsive width, #B0BEC5 / #1565C0 bg, white text
/// - Rebus key: responsive width, neutral (keyDefault) bg, w600 label,
///   bottom-right corner — matches the NYT Games convention so that the
///   key is recognizable to solvers coming from other apps. See
///   `docs/architecture/rebus-entry.md`.
/// - Three rows: QWERTYUIOP / ASDFGHJKL / ⌫ZXCVBNM✓Rebus
///
/// Physical keyboard input is still handled via the hidden [TextField] in
/// [CrosswordGrid]; this widget handles soft-keyboard input only.
class CrosswordKeyboard extends StatelessWidget {
  const CrosswordKeyboard({
    super.key,
    required this.onLetter,
    required this.onBackspace,
    required this.onCheckWord,
    required this.onRebus,
    required this.onFeedbackSound,
    this.isSmallPuzzle = false,
    this.hapticsEnabled = true,
    this.soundsEnabled = false,
  });

  final void Function(String letter) onLetter;
  final VoidCallback onBackspace;
  final VoidCallback onCheckWord;

  /// Opens the rebus entry dialog for the currently focused cell.
  /// Always available (the key is on every puzzle so its presence
  /// leaks no information about whether the puzzle contains a rebus).
  final VoidCallback onRebus;

  final VoidCallback onFeedbackSound;
  final bool isSmallPuzzle;
  final bool hapticsEnabled;
  final bool soundsEnabled;

  static const _row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  static const _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  static const _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  Widget build(BuildContext context) {
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();
    final metrics = isSmallPuzzle
        ? const _KeyMetrics(height: 54, letterFontSize: 17)
        : const _KeyMetrics(height: 50, letterFontSize: 16);

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
            metrics: metrics,
          ),
          const SizedBox(height: 4),
          _KeyRow(
            keys: _row2,
            onLetter: _tap,
            xwTheme: xwTheme,
            metrics: metrics,
          ),
          const SizedBox(height: 4),
          _BottomKeyRow(
            keys: _row3,
            onLetter: _tap,
            onBackspace: () {
              if (hapticsEnabled) HapticFeedback.selectionClick();
              _playSound();
              onBackspace();
            },
            onCheckWord: () {
              if (hapticsEnabled) HapticFeedback.lightImpact();
              onCheckWord();
            },
            onRebus: () {
              if (hapticsEnabled) HapticFeedback.lightImpact();
              onRebus();
            },
            xwTheme: xwTheme,
            metrics: metrics,
          ),
        ],
      ),
    );
  }

  void _tap(String letter) {
    if (hapticsEnabled) HapticFeedback.lightImpact();
    _playSound();
    onLetter(letter);
  }

  void _playSound() {
    if (soundsEnabled) onFeedbackSound();
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
    required this.metrics,
  });

  final List<String> keys;
  final void Function(String) onLetter;
  final CrosswordTheme xwTheme;
  final _KeyMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth =
            (constraints.maxWidth - (keys.length - 1) * 3) / keys.length;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              _LetterKey(
                letter: keys[i],
                width: keyWidth,
                onTap: () => onLetter(keys[i]),
                xwTheme: xwTheme,
                metrics: metrics,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BottomKeyRow extends StatelessWidget {
  const _BottomKeyRow({
    required this.keys,
    required this.onLetter,
    required this.onBackspace,
    required this.onCheckWord,
    required this.onRebus,
    required this.xwTheme,
    required this.metrics,
  });

  final List<String> keys;
  final void Function(String) onLetter;
  final VoidCallback onBackspace;
  final VoidCallback onCheckWord;
  final VoidCallback onRebus;
  final CrosswordTheme xwTheme;
  final _KeyMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Layout budget on the bottom row:
        //   ⌫ (1.3u) + 7 letters (1u each) + ✓ (1.3u) + Rebus (1.7u)
        // Rebus is wider than ⌫/✓ to fit the four-letter label without
        // crowding. Three specials + N letters → unit math:
        const backspaceUnits = 1.3;
        const checkUnits = 1.3;
        const rebusUnits = 1.7;
        const specialUnitsTotal = backspaceUnits + checkUnits + rebusUnits;
        const numSpecials = 3;
        final gapTotal = (keys.length + numSpecials - 1) * 3;
        final unit = (constraints.maxWidth - gapTotal) /
            (keys.length + specialUnitsTotal);
        final keyWidth = unit;
        final backspaceWidth = unit * backspaceUnits;
        final checkWidth = unit * checkUnits;
        final rebusWidth = unit * rebusUnits;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SpecialKey(
              label: '⌫',
              width: backspaceWidth,
              color: xwTheme.keySpecial,
              textColor: Colors.white,
              metrics: metrics,
              onTap: onBackspace,
            ),
            const SizedBox(width: 3),
            for (final letter in keys) ...[
              _LetterKey(
                letter: letter,
                width: keyWidth,
                onTap: () => onLetter(letter),
                xwTheme: xwTheme,
                metrics: metrics,
              ),
              const SizedBox(width: 3),
            ],
            _SpecialKey(
              label: '✓',
              width: checkWidth,
              color: xwTheme.keyCheck,
              textColor: Colors.white,
              metrics: metrics,
              onTap: onCheckWord,
            ),
            const SizedBox(width: 3),
            _SpecialKey(
              label: 'Rebus',
              width: rebusWidth,
              color: xwTheme.keyDefault,
              textColor: context.crosscueOnSurface1,
              metrics: metrics,
              onTap: onRebus,
              fontSize: 12,
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Standard letter key
// ---------------------------------------------------------------------------

class _LetterKey extends StatelessWidget {
  const _LetterKey({
    required this.letter,
    required this.width,
    required this.onTap,
    required this.xwTheme,
    required this.metrics,
  });

  final String letter;
  final double width;
  final VoidCallback onTap;
  final CrosswordTheme xwTheme;
  final _KeyMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: metrics.height,
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
          style: TextStyle(
            fontSize: metrics.letterFontSize,
            fontWeight: FontWeight.w500,
            color: context.crosscueOnSurface1,
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
    required this.width,
    required this.color,
    required this.textColor,
    required this.metrics,
    required this.onTap,
    this.fontSize = 14,
  });

  final String label;
  final double width;
  final Color color;
  final Color textColor;
  final _KeyMetrics metrics;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: metrics.height,
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
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _KeyMetrics {
  const _KeyMetrics({
    required this.height,
    required this.letterFontSize,
  });

  final double height;
  final double letterFontSize;
}
