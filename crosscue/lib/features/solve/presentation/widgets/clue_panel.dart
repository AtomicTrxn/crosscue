import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:flutter/material.dart';

/// The clue display beneath the grid: the **Across** clue (always top) and the
/// **Down** clue (always bottom) at the focused cell, both shown in full.
///
/// The active clue — the direction you're filling — is highlighted and carries
/// ‹ › arrows to step through that direction; tapping the other clue switches
/// to it (the highlight + arrows move). Both clues are derived from the live
/// grid focus, so the crossing clue updates as the cursor advances along a word.
///
/// Replaces the older scrolling two-column list: navigation is via the grid,
/// tap-to-switch, the arrows, and auto-advance on word completion.
class CluePanel extends StatelessWidget {
  const CluePanel({
    super.key,
    required this.activeClue,
    required this.crossClue,
    required this.onSelectClue,
    required this.onPrev,
    required this.onNext,
  });

  /// The clue for the current solving direction (focus.direction).
  final Clue? activeClue;

  /// The perpendicular clue at the focused cell, if the cell has one.
  final Clue? crossClue;

  /// Called when the user taps the inactive clue to switch direction to it.
  final ValueChanged<Clue> onSelectClue;

  /// Step to the previous / next clue in the active direction (the ‹ › arrows).
  final VoidCallback onPrev;
  final VoidCallback onNext;

  /// Below this much vertical room, show only the active clue (the crossing
  /// clue is one grid-tap away). Keyed on *measured* height — not device
  /// class — so it adapts to Dynamic Type, landscape, and iPad split-view too.
  static const double _showBothMinHeight = 100;

  @override
  Widget build(BuildContext context) {
    final active = activeClue;
    if (active == null) return const SizedBox.shrink();

    // Place each clue by direction: Across on top, Down on the bottom.
    Clue? across;
    Clue? down;
    for (final c in [active, if (crossClue != null) crossClue!]) {
      if (c.direction == Direction.across) across = c;
      if (c.direction == Direction.down) down = c;
    }

    _ClueRow row(Clue clue) => _ClueRow(
          clue: clue,
          active: active.direction == clue.direction,
          onSelect: onSelectClue,
          onPrev: onPrev,
          onNext: onNext,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showBoth = across != null &&
            down != null &&
            constraints.maxHeight >= _showBothMinHeight;

        // Each clue takes the height it needs (full text); the whole block
        // scrolls only if it genuinely overflows the band — so a long clue is
        // never clipped into the keyboard, and a short one doesn't get a
        // squeezed half. Tight band / single-direction cell → active only.
        final children = showBoth
            ? [
                row(across),
                Divider(height: 1, color: context.crosscueDivider),
                row(down),
              ]
            : [row(active)];

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );
      },
    );
  }
}

class _ClueRow extends StatelessWidget {
  const _ClueRow({
    required this.clue,
    required this.active,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
  });

  final Clue clue;
  final bool active;
  final ValueChanged<Clue> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();
    final label =
        '${clue.number}${clue.direction == Direction.across ? 'A' : 'D'}';

    final labelWidget = Padding(
      padding: const EdgeInsets.only(top: 1, right: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: active ? xwTheme.clueBarDirection : context.crosscueOnSurface3,
        ),
      ),
    );
    final textWidget = Expanded(
      child: Text(
        clue.text,
        style: TextStyle(
          fontSize: 16,
          height: 1.3,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color:
              active ? context.crosscueOnSurface1 : context.crosscueOnSurface2,
        ),
      ),
    );

    if (active) {
      return Material(
        color: xwTheme.activeClueBg,
        child: Row(
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
              color: xwTheme.clueBarDirection,
              tooltip: 'Previous clue',
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [labelWidget, textWidget],
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              color: xwTheme.clueBarDirection,
              tooltip: 'Next clue',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    // Inactive clue — tap to switch direction. Inset so its text lines up with
    // the active row's text (past the arrow gutter), so nothing jumps.
    return InkWell(
      onTap: () => onSelect(clue),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 12, 40, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelWidget, textWidget],
        ),
      ),
    );
  }
}
