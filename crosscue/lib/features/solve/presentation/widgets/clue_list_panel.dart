import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:flutter/material.dart';

/// Scrollable Across/Down clue list for the landscape solve layout — lets a
/// solver scan and jump to any clue instead of stepping one at a time via the
/// grid, freeing up the extra horizontal room landscape (esp. tablet)
/// provides. See [CluePanel] for the compact active/cross clue bar this
/// complements.
class ClueListPanel extends StatefulWidget {
  const ClueListPanel({
    super.key,
    required this.clues,
    required this.activeClue,
    required this.solveState,
    required this.onSelectClue,
  });

  /// All clues, sorted (see `SolveState.sortedClues`).
  final List<Clue> clues;

  /// The clue currently being filled — highlighted and auto-scrolled to.
  final Clue? activeClue;

  final SolveState solveState;
  final ValueChanged<Clue> onSelectClue;

  @override
  State<ClueListPanel> createState() => _ClueListPanelState();
}

/// Uniform row height for every list entry (section headers included) so the
/// active clue's scroll offset can be computed directly from its index
/// instead of relying on `Scrollable.ensureVisible`, which silently no-ops
/// for rows the lazy `ListView` hasn't mounted yet — the common case for a
/// full-size (15×15+) puzzle where the active clue is far from the top.
const double _rowExtent = 56;

sealed class _ListEntry {
  const _ListEntry();
}

class _HeaderEntry extends _ListEntry {
  const _HeaderEntry(this.label);
  final String label;
}

class _ClueEntry extends _ListEntry {
  const _ClueEntry(this.clue);
  final Clue clue;
}

class _ClueListPanelState extends State<ClueListPanel> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Land on the active clue on first build too (e.g. rotating into
    // landscape mid-puzzle), not just on later changes.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  @override
  void didUpdateWidget(covariant ClueListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final active = widget.activeClue;
    final changed = active != null &&
        (oldWidget.activeClue?.number != active.number ||
            oldWidget.activeClue?.direction != active.direction);
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_ListEntry> _buildEntries() {
    final across = widget.clues.where((c) => c.direction == Direction.across);
    final down = widget.clues.where((c) => c.direction == Direction.down);
    return [
      if (across.isNotEmpty) const _HeaderEntry('Across'),
      for (final clue in across) _ClueEntry(clue),
      if (down.isNotEmpty) const _HeaderEntry('Down'),
      for (final clue in down) _ClueEntry(clue),
    ];
  }

  void _scrollToActive() {
    if (!mounted || !_scrollController.hasClients) return;
    final active = widget.activeClue;
    if (active == null) return;

    final entries = _buildEntries();
    final index = entries.indexWhere(
      (e) =>
          e is _ClueEntry &&
          e.clue.number == active.number &&
          e.clue.direction == active.direction,
    );
    if (index < 0) return;

    final position = _scrollController.position;
    final target = (index * _rowExtent - position.viewportDimension * 0.3)
        .clamp(0.0, position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemExtent: _rowExtent,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          _HeaderEntry(:final label) => _SectionHeader(label),
          _ClueEntry(:final clue) => _row(clue),
        };
      },
    );
  }

  Widget _row(Clue clue) {
    final active = widget.activeClue?.number == clue.number &&
        widget.activeClue?.direction == clue.direction;
    // "Filled", not "correct" — this is a progress marker, not a free
    // checker. Using solution-correctness here would silently tell the
    // solver an answer is right without them ever using Check/Reveal.
    final filled = _isClueFilled(widget.solveState, clue);
    return _ClueListRow(
      clue: clue,
      active: active,
      filled: filled,
      onTap: () => widget.onSelectClue(clue),
    );
  }

  bool _isClueFilled(SolveState state, Clue clue) {
    for (final (row, col) in ClueProgressCalculator.cellsFor(clue)) {
      if (state.progress.cell(row, col).letter.isEmpty) return false;
    }
    return true;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: context.crosscueOnSurface3,
          ),
        ),
      ),
    );
  }
}

class _ClueListRow extends StatelessWidget {
  const _ClueListRow({
    required this.clue,
    required this.active,
    required this.filled,
    required this.onTap,
  });

  final Clue clue;
  final bool active;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();
    final spokenClue =
        '${clue.number} ${clue.direction == Direction.across ? 'Across' : 'Down'}, ${clue.text}'
        '${filled ? ', filled' : ''}';

    return Semantics(
      button: true,
      selected: active,
      label: spokenClue,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: active ? xwTheme.activeClueBg : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${clue.number}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: active
                          ? xwTheme.clueBarDirection
                          : context.crosscueOnSurface3,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    clue.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: filled && !active
                          ? context.crosscueOnSurface3
                          : context.crosscueOnSurface1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
