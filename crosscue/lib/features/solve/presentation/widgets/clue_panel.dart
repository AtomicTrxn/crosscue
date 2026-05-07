import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';

/// Two-column clue panel with independently scrollable Across / Down lists.
class CluePanel extends StatelessWidget {
  const CluePanel({
    super.key,
    required this.solveState,
    required this.onClueTap,
    required this.hapticsEnabled,
  });

  final SolveState solveState;
  final ValueChanged<Clue> onClueTap;
  final bool hapticsEnabled;

  @override
  Widget build(BuildContext context) {
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();

    final acrossClues = solveState.puzzle.clues
        .where((c) => c.direction == Direction.across)
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final downClues = solveState.puzzle.clues
        .where((c) => c.direction == Direction.down)
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ClueColumn(
            header: 'Across',
            clues: acrossClues,
            activeClue: solveState.activeClue,
            crossClue: solveState.crossClue,
            xwTheme: xwTheme,
            hapticsEnabled: hapticsEnabled,
            onClueTap: onClueTap,
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          child: _ClueColumn(
            header: 'Down',
            clues: downClues,
            activeClue: solveState.activeClue,
            crossClue: solveState.crossClue,
            xwTheme: xwTheme,
            hapticsEnabled: hapticsEnabled,
            onClueTap: onClueTap,
          ),
        ),
      ],
    );
  }
}

const double _kHeaderH = 28.0;
const double _kRowPadH = 10.0;
const double _kRowH = 42.0;

class _ClueColumn extends StatefulWidget {
  const _ClueColumn({
    required this.header,
    required this.clues,
    required this.activeClue,
    required this.crossClue,
    required this.xwTheme,
    required this.hapticsEnabled,
    required this.onClueTap,
  });

  final String header;
  final List<Clue> clues;
  final Clue? activeClue;
  final Clue? crossClue;
  final CrosswordTheme xwTheme;
  final bool hapticsEnabled;
  final ValueChanged<Clue> onClueTap;

  @override
  State<_ClueColumn> createState() => _ClueColumnState();
}

class _ClueColumnState extends State<_ClueColumn> {
  late final ScrollController _controller;
  Clue? _previewClue;
  bool _userScrolling = false;
  Timer? _scrollEndDebounce;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_handleScroll);
    _previewClue = _selectedClue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToSelected(jump: true);
    });
  }

  @override
  void didUpdateWidget(covariant _ClueColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_userScrolling && !_sameClue(_previewClue, _selectedClue)) {
      _previewClue = _selectedClue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToSelected();
      });
    }
  }

  @override
  void dispose() {
    _scrollEndDebounce?.cancel();
    _controller
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: CrosscueColors.onSurface3Light,
      letterSpacing: 1.0,
      height: 1.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _kHeaderH,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_kRowPadH, 7, _kRowPadH, 4),
            child: Text(widget.header.toUpperCase(), style: headerStyle),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: ListView.builder(
              controller: _controller,
              padding: EdgeInsets.zero,
              itemExtent: _kRowH,
              itemCount: widget.clues.length,
              itemBuilder: (context, index) {
                final clue = widget.clues[index];
                return _ClueRow(
                  clue: clue,
                  activeClue: widget.activeClue,
                  crossClue: widget.crossClue,
                  previewClue: _previewClue,
                  xwTheme: widget.xwTheme,
                  onClueTap: (clue) {
                    setState(() => _previewClue = clue);
                    widget.onClueTap(clue);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      _userScrolling = true;
    }
    if (notification is ScrollEndNotification && _userScrolling) {
      _scrollEndDebounce?.cancel();
      _scrollEndDebounce = Timer(const Duration(milliseconds: 80), () {
        final clue = _previewClue;
        if (clue == null || !mounted) return;
        _userScrolling = false;
        widget.onClueTap(clue);
      });
    }
    return false;
  }

  void _handleScroll() {
    if (!_controller.hasClients || widget.clues.isEmpty) return;
    final index =
        (_controller.offset / _kRowH).round().clamp(0, widget.clues.length - 1);
    final clue = widget.clues[index];
    if (_sameClue(clue, _previewClue)) return;
    setState(() => _previewClue = clue);
    if (_userScrolling && widget.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  Clue? get _selectedClue {
    final columnDirection = widget.header.toLowerCase() == 'across'
        ? Direction.across
        : Direction.down;
    if (widget.activeClue?.direction == columnDirection) {
      return widget.activeClue;
    }
    if (widget.crossClue?.direction == columnDirection) return widget.crossClue;
    return widget.clues.isEmpty ? null : widget.clues.first;
  }

  void _scrollToSelected({bool jump = false}) {
    final clue = _selectedClue;
    if (clue == null || !_controller.hasClients) return;
    final index = widget.clues.indexWhere((c) => _sameClue(c, clue));
    if (index < 0) return;
    final offset = index * _kRowH;
    if (jump) {
      _controller.jumpTo(offset);
    } else {
      _controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  bool _sameClue(Clue? a, Clue? b) {
    return a?.number == b?.number && a?.direction == b?.direction;
  }
}

class _ClueRow extends StatelessWidget {
  const _ClueRow({
    required this.clue,
    required this.activeClue,
    required this.crossClue,
    required this.previewClue,
    required this.xwTheme,
    required this.onClueTap,
  });

  final Clue clue;
  final Clue? activeClue;
  final Clue? crossClue;
  final Clue? previewClue;
  final CrosswordTheme xwTheme;
  final ValueChanged<Clue> onClueTap;

  @override
  Widget build(BuildContext context) {
    final isActive = activeClue?.number == clue.number &&
        activeClue?.direction == clue.direction;
    final isCross = crossClue?.number == clue.number &&
        crossClue?.direction == clue.direction;
    final isPreview = previewClue?.number == clue.number &&
        previewClue?.direction == clue.direction;

    Color? rowBg;
    if (isActive || isPreview) {
      rowBg = xwTheme.activeClueBg;
    } else if (isCross) {
      rowBg = xwTheme.crossClueBg;
    }

    final highlighted = isActive || isCross || isPreview;
    final numStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: highlighted
          ? xwTheme.clueBarDirection
          : CrosscueColors.onSurface3Light,
      height: 1.3,
    );
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
      color: highlighted ? xwTheme.clueBarDirection : xwTheme.cellNumber,
      height: 1.3,
    );

    return Material(
      color: rowBg ?? Colors.transparent,
      child: InkWell(
        onTap: () => onClueTap(clue),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: _kRowPadH,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                child: Text('${clue.number}', style: numStyle),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  clue.text,
                  style: textStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
