import 'package:flutter/material.dart';

import '../../../../core/theme/crossword_theme.dart';
import '../../domain/models/clue.dart';
import '../../domain/models/enums.dart';
import '../notifiers/solve_state.dart';

/// Two-column scrollable clue panel (Sprint 10).
///
/// Design spec:
/// - Two equal columns: ACROSS (left) + DOWN (right), 1px divider between.
/// - Header: 10px w700 #999999 UPPERCASE letterSpacing 0.1em, 7dp top / 10dp H padding.
/// - Clue row: 3dp vertical, 10dp horizontal.
///   - Number: 10px w600 #999999, width 14dp.
///   - Text: 11px #555555 lineHeight 1.3.
///   - Active clue bg: word = #BBDEFB, cross = #E3F2FD.
///   - Active clue text: #1565C0 w600.
/// - Auto-scroll active clue into view (150ms easeOut).
class CluePanel extends StatefulWidget {
  const CluePanel({super.key, required this.solveState});

  final SolveState solveState;

  @override
  State<CluePanel> createState() => _CluePanelState();
}

class _CluePanelState extends State<CluePanel> {
  final _acrossController = ScrollController();
  final _downController = ScrollController();

  @override
  void dispose() {
    _acrossController.dispose();
    _downController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CluePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll active clue into view when focus changes.
    final state = widget.solveState;
    final oldState = oldWidget.solveState;
    if (state.focus != oldState.focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollActiveIntoView(state);
      });
    }
  }

  void _scrollActiveIntoView(SolveState state) {
    final acrossClues =
        widget.solveState.puzzle.clues.where((c) => c.direction == Direction.across).toList();
    final downClues =
        widget.solveState.puzzle.clues.where((c) => c.direction == Direction.down).toList();

    final activeClue = state.activeClue;
    final crossClue = state.crossClue;

    if (activeClue != null) {
      final ctrl = activeClue.direction == Direction.across
          ? _acrossController
          : _downController;
      final clues = activeClue.direction == Direction.across ? acrossClues : downClues;
      _scrollToClue(ctrl, clues, activeClue);
    }
    if (crossClue != null) {
      final ctrl = crossClue.direction == Direction.across
          ? _acrossController
          : _downController;
      final clues = crossClue.direction == Direction.across ? acrossClues : downClues;
      _scrollToClue(ctrl, clues, crossClue);
    }
  }

  void _scrollToClue(
    ScrollController ctrl,
    List<Clue> clues,
    Clue target,
  ) {
    if (!ctrl.hasClients) return;
    const rowH = _kRowH;
    const headerH = _kHeaderH;
    final idx = clues.indexWhere((c) => c.number == target.number);
    if (idx < 0) return;
    final offset = (headerH + idx * rowH).clamp(
      0.0,
      ctrl.position.maxScrollExtent,
    );
    ctrl.animateTo(
      offset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.solveState;
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();

    final acrossClues = state.puzzle.clues
        .where((c) => c.direction == Direction.across)
        .toList();
    final downClues =
        state.puzzle.clues.where((c) => c.direction == Direction.down).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ACROSS column
        Expanded(
          child: _ClueColumn(
            header: 'Across',
            clues: acrossClues,
            activeClue: state.activeClue,
            crossClue: state.crossClue,
            controller: _acrossController,
            xwTheme: xwTheme,
          ),
        ),

        // Divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),

        // DOWN column
        Expanded(
          child: _ClueColumn(
            header: 'Down',
            clues: downClues,
            activeClue: state.activeClue,
            crossClue: state.crossClue,
            controller: _downController,
            xwTheme: xwTheme,
          ),
        ),
      ],
    );
  }
}

// Row / header heights used for scroll offset math.
const double _kHeaderH = 28.0; // 7dp top + ~10dp text + 11dp bottom ≈ 28
const double _kRowV = 3.0;
const double _kRowH = 10.0;

class _ClueColumn extends StatelessWidget {
  const _ClueColumn({
    required this.header,
    required this.clues,
    required this.activeClue,
    required this.crossClue,
    required this.controller,
    required this.xwTheme,
  });

  final String header;
  final List<Clue> clues;
  final Clue? activeClue;
  final Clue? crossClue;
  final ScrollController controller;
  final CrosswordTheme xwTheme;

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: xwTheme.cellNumber, // #999999 token
      letterSpacing: 1.0,
      height: 1.2,
    );

    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.zero,
      itemCount: clues.length + 1, // +1 for header
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              _kRowH,
              7,
              _kRowH,
              4,
            ),
            child: Text(header.toUpperCase(), style: headerStyle),
          );
        }
        final clue = clues[i - 1];
        final isActive = activeClue?.number == clue.number &&
            activeClue?.direction == clue.direction;
        final isCross = crossClue?.number == clue.number &&
            crossClue?.direction == clue.direction;

        Color? rowBg;
        if (isActive) {
          rowBg = xwTheme.activeClueBg;
        } else if (isCross) {
          rowBg = xwTheme.crossClueBg;
        }

        final numStyle = TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive || isCross
              ? xwTheme.clueBarDirection
              : xwTheme.cellNumber,
          height: 1.3,
        );
        final textStyle = TextStyle(
          fontSize: 11,
          fontWeight: isActive || isCross ? FontWeight.w600 : FontWeight.w400,
          color: isActive || isCross
              ? xwTheme.clueBarDirection
              : xwTheme.cellNumber,
          height: 1.3,
        );

        return Container(
          color: rowBg,
          padding: const EdgeInsets.symmetric(
            vertical: _kRowV,
            horizontal: _kRowH,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 14,
                child: Text('${clue.number}', style: numStyle),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  clue.text,
                  style: textStyle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
