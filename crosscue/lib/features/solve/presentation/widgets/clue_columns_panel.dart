import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:flutter/material.dart';

/// Two independently scrollable Across / Down clue lists, side by side —
/// the landscape-only counterpart to [ClueListPanel]'s single merged list.
///
/// This is a revival of the app's original two-column clue panel (removed
/// in #154 when the solve screen's clue area became the compact two-clue
/// [CluePanel] bar) — brought back because a single merged list can't show
/// the active clue and its cross clue at once without scrolling between
/// Across and Down sections. Landscape has the width to spare for two
/// columns; portrait doesn't, so it keeps the single-list [ClueListPanel].
///
/// Each column tracks whichever of [activeClue] / [crossClue] belongs to
/// its own direction and auto-scrolls to keep it in view — so selecting a
/// clue in one column (tap-to-jump, same as [ClueListPanel]) scrolls the
/// *other* column to reveal the resulting cross clue.
class ClueColumnsPanel extends StatelessWidget {
  const ClueColumnsPanel({
    super.key,
    required this.clues,
    required this.activeClue,
    required this.crossClue,
    required this.solveState,
    required this.onSelectClue,
  });

  /// All clues, sorted (see `SolveState.sortedClues`).
  final List<Clue> clues;
  final Clue? activeClue;
  final Clue? crossClue;
  final SolveState solveState;
  final ValueChanged<Clue> onSelectClue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ClueColumn(
            direction: Direction.across,
            label: 'Across',
            clues: clues,
            activeClue: activeClue,
            crossClue: crossClue,
            solveState: solveState,
            onSelectClue: onSelectClue,
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: context.crosscueDivider,
        ),
        Expanded(
          child: _ClueColumn(
            direction: Direction.down,
            label: 'Down',
            clues: clues,
            activeClue: activeClue,
            crossClue: crossClue,
            solveState: solveState,
            onSelectClue: onSelectClue,
          ),
        ),
      ],
    );
  }
}

const double _rowExtent = 56;

class _ClueColumn extends StatefulWidget {
  const _ClueColumn({
    required this.direction,
    required this.label,
    required this.clues,
    required this.activeClue,
    required this.crossClue,
    required this.solveState,
    required this.onSelectClue,
  });

  final Direction direction;
  final String label;
  final List<Clue> clues;
  final Clue? activeClue;
  final Clue? crossClue;
  final SolveState solveState;
  final ValueChanged<Clue> onSelectClue;

  @override
  State<_ClueColumn> createState() => _ClueColumnState();
}

class _ClueColumnState extends State<_ClueColumn> {
  final _scrollController = ScrollController();

  /// The clue this column should track and keep in view — [activeClue] if
  /// it's this column's direction (the solver is filling this direction),
  /// otherwise [crossClue] if that's this column's direction (the solver
  /// is filling the *other* direction and this column shows where their
  /// current cell crosses into this one).
  Clue? get _tracked {
    final active = widget.activeClue;
    if (active != null && active.direction == widget.direction) return active;
    final cross = widget.crossClue;
    if (cross != null && cross.direction == widget.direction) return cross;
    return null;
  }

  List<Clue> get _columnClues =>
      widget.clues.where((c) => c.direction == widget.direction).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTracked());
  }

  @override
  void didUpdateWidget(covariant _ClueColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = _trackedFor(oldWidget);
    final current = _tracked;
    final changed = current != null &&
        (old?.number != current.number || old?.direction != current.direction);
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTracked());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Clue? _trackedFor(_ClueColumn widget) {
    final active = widget.activeClue;
    if (active != null && active.direction == widget.direction) return active;
    final cross = widget.crossClue;
    if (cross != null && cross.direction == widget.direction) return cross;
    return null;
  }

  void _scrollToTracked() {
    if (!mounted || !_scrollController.hasClients) return;
    final tracked = _tracked;
    if (tracked == null) return;

    final columnClues = _columnClues;
    final index = columnClues.indexWhere(
      (c) => c.number == tracked.number && c.direction == tracked.direction,
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
    final columnClues = _columnClues;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ColumnHeader(widget.label),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemExtent: _rowExtent,
            itemCount: columnClues.length,
            itemBuilder: (context, index) => _row(columnClues[index]),
          ),
        ),
      ],
    );
  }

  Widget _row(Clue clue) {
    final active = widget.activeClue?.number == clue.number &&
        widget.activeClue?.direction == clue.direction;
    final crossActive = !active &&
        widget.crossClue?.number == clue.number &&
        widget.crossClue?.direction == clue.direction;
    // "Filled", not "correct" — a progress marker, not a free checker. Using
    // solution-correctness would silently tell the solver an answer is right
    // without them ever using Check/Reveal.
    final filled = _isClueFilled(widget.solveState, clue);
    return _ClueColumnRow(
      clue: clue,
      active: active,
      crossActive: crossActive,
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

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
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

class _ClueColumnRow extends StatelessWidget {
  const _ClueColumnRow({
    required this.clue,
    required this.active,
    required this.crossActive,
    required this.filled,
    required this.onTap,
  });

  final Clue clue;
  final bool active;
  final bool crossActive;
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
        color: active
            ? xwTheme.activeClueBg
            : crossActive
                ? xwTheme.cluePanelCrossRowBg
                : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
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
