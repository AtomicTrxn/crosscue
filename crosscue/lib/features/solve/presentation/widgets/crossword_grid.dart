import 'dart:async';

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/check_result.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/widgets/crossword_grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'crossword_grid_effects.dart';
part 'crossword_grid_input.dart';

// Compiled once; reused on every physical-keyboard event and rebus keystroke.
final _letterRe = RegExp(r'^[A-Za-z]$');
final _letterFilterRe = RegExp('[A-Za-z]');

/// The interactive crossword grid.
///
/// Handles:
///  - Tap → cell focus + optional haptic feedback
///  - Long-press → contextual Check/Reveal popup menu (ISSUES #2)
///  - Physical keyboard → letter input / backspace
///  - Soft keyboard → via hidden TextField overlay
class CrosswordGrid extends ConsumerStatefulWidget {
  const CrosswordGrid({
    super.key,
    required this.puzzleId,
    required this.solveState,
    this.onGridFocusSelected,
  });

  final String puzzleId;
  final SolveState solveState;
  final ValueChanged<FocusPosition>? onGridFocusSelected;

  @override
  ConsumerState<CrosswordGrid> createState() => _CrosswordGridState();
}

class _CrosswordGridState extends ConsumerState<CrosswordGrid>
    with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode();
  final _textController = TextEditingController();
  late final AnimationController _effectController;
  Map<(int, int), GridCellEffect> _effects = const {};
  SolveState? _previousSolveStateForEffect;
  bool _hapticsEnabled = true;
  bool _soundsEnabled = false;

  @override
  void initState() {
    super.initState();
    _effectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Attach physical-keyboard handler directly to the FocusNode so the
    // TextField is the sole widget owner of the node (avoids the
    // "child into parent of itself" assertion).
    _focusNode.onKeyEvent = _onKeyEvent;
    ref.listenManual(
      hapticsEnabledProvider,
      (_, next) => _hapticsEnabled = _settingValue(next, fallback: true),
      fireImmediately: true,
    );
    ref.listenManual(
      soundsEnabledProvider,
      (_, next) => _soundsEnabled = _settingValue(next, fallback: false),
      fireImmediately: true,
    );
  }

  @override
  void didUpdateWidget(CrosswordGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startCellEffects(oldWidget.solveState, widget.solveState);
  }

  @override
  void dispose() {
    _effectController.dispose();
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool _settingValue(AsyncValue<bool> value, {required bool fallback}) {
    return value.when(
      data: (v) => v,
      loading: () => fallback,
      error: (_, __) => fallback,
    );
  }

  void _setCellEffects(
    Map<(int, int), GridCellEffect> effects,
    SolveState previous,
  ) {
    setState(() {
      _effects = effects;
      _previousSolveStateForEffect = previous;
    });
  }

  void _clearCellEffects() {
    setState(() {
      _effects = const {};
      _previousSolveStateForEffect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.solveState.puzzle;
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();
    final colorblindMode = ref.watch(colorblindModeProvider).when(
          data: (mode) => mode,
          loading: () => ColorblindMode.none,
          error: (_, __) => ColorblindMode.none,
        );
    final animationsDisabled = MediaQuery.of(context).disableAnimations;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Full-width layout: cell size driven by screen width (Sprint 10).
        // The widget sizes itself to exactly gridH tall so the parent Column
        // never needs to know the grid dimensions.
        final cellSize = constraints.maxWidth / puzzle.width;
        final gridH = cellSize * puzzle.height;

        return SizedBox(
          height: gridH,
          child: Stack(
            children: [
              // Grid painter
              GestureDetector(
                onTapDown: (details) => _onTap(
                  context,
                  details.localPosition,
                  cellSize,
                  0, // no horizontal offset — full width
                  0, // no vertical offset — exact height
                ),
                onLongPressStart: (details) => _onLongPress(
                  context,
                  details.localPosition,
                  cellSize,
                  0,
                  0,
                ),
                child: AnimatedBuilder(
                  animation: _effectController,
                  builder: (context, _) => CustomPaint(
                    size: Size(constraints.maxWidth, gridH),
                    painter: CrosswordGridPainter(
                      puzzle: puzzle,
                      progress: widget.solveState.progress,
                      solveState: widget.solveState,
                      theme: xwTheme,
                      colorblindMode: colorblindMode,
                      previousSolveState: animationsDisabled
                          ? null
                          : _previousSolveStateForEffect,
                      effects: animationsDisabled ? const {} : _effects,
                      effectValue: animationsDisabled
                          ? 1.0
                          : Curves.easeOut.transform(_effectController.value),
                    ),
                  ),
                ),
              ),

              // Hidden TextField — sole owner of _focusNode.
              // Physical keyboard is handled via _focusNode.onKeyEvent (set in
              // initState). Soft keyboard input comes through onChanged.
              // keyboardType.none suppresses the system keyboard so our custom
              // CrosswordKeyboard widget is the only visible input surface.
              Positioned(
                left: -200,
                top: -200,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _textController,
                    keyboardType: TextInputType.none,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        // Backspace from soft keyboard
                        ref
                            .read(solveProvider(widget.puzzleId).notifier)
                            .backspace();
                      } else {
                        // New character appended
                        final last = value.characters.last;
                        _pulseIfWordComplete(
                          ref
                              .read(solveProvider(widget.puzzleId).notifier)
                              .inputLetter(last),
                        );
                      }
                      // Reset so every keystroke is detected as a change
                      _textController.clear();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
