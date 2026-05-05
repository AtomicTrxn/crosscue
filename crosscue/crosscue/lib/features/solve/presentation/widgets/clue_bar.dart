import 'package:flutter/material.dart';

import '../../../../core/theme/crossword_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/models/clue.dart';
import '../../domain/models/enums.dart';
import '../notifiers/solve_state.dart';

/// Compact bar above the grid showing the active clue with direction prefix.
///
/// Design spec (Sprint 10):
/// - Background: clueBarBg (`#E3F2FD` light / dark variant)
/// - Bottom border: 1.5px clueBarBorder (`#BBDEFB`)
/// - Padding: 9dp vertical, 12dp horizontal
/// - Direction prefix: ↔ / ↕ — 12px w700 clueBarDirection colour
/// - Clue number label: e.g. "14A" — same style as prefix
/// - Clue text: 13px #1A1A1A lineHeight 1.35
/// - Tapping toggles direction (calls onToggleDirection)
class ClueBar extends StatelessWidget {
  const ClueBar({
    super.key,
    required this.solveState,
    required this.onToggleDirection,
  });

  final SolveState solveState;
  final VoidCallback onToggleDirection;

  @override
  Widget build(BuildContext context) {
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();

    final activeClue = solveState.activeClue;
    final isAcross = solveState.focus.direction == Direction.across;

    return GestureDetector(
      onTap: onToggleDirection,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: xwTheme.clueBarBg,
          border: Border(
            bottom: BorderSide(color: xwTheme.clueBarBorder, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: CrosscueSpacing.clueBarV,
          horizontal: CrosscueSpacing.clueBarH,
        ),
        child: _ClueBarContent(
          clue: activeClue,
          isAcross: isAcross,
          xwTheme: xwTheme,
        ),
      ),
    );
  }
}

class _ClueBarContent extends StatelessWidget {
  const _ClueBarContent({
    required this.clue,
    required this.isAcross,
    required this.xwTheme,
  });

  final Clue? clue;
  final bool isAcross;
  final CrosswordTheme xwTheme;

  @override
  Widget build(BuildContext context) {
    final directionArrow = isAcross ? '↔' : '↕';
    final dirStyle = TextStyle(
      fontSize: CrosscueTypography.clueBarDirection,
      fontWeight: FontWeight.w700,
      color: xwTheme.clueBarDirection,
      height: 1.2,
    );
    final textStyle = TextStyle(
      fontSize: CrosscueTypography.clueBarText,
      fontWeight: FontWeight.w400,
      color: xwTheme.clueBarText,
      height: 1.35,
    );

    if (clue == null) {
      return Row(
        children: [
          Text(directionArrow, style: dirStyle),
          const SizedBox(width: 6),
          Text('Tap a cell to begin', style: textStyle),
        ],
      );
    }

    final dirLabel = clue!.direction == Direction.across ? 'A' : 'D';
    final numberLabel = '${clue!.number}$dirLabel';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(directionArrow, style: dirStyle),
        const SizedBox(width: 4),
        Text(numberLabel, style: dirStyle),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            clue!.text,
            style: textStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
