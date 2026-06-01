part of 'crossword_grid.dart';

extension _CrosswordGridInput on _CrosswordGridState {
  void _requestFocus() {
    _focusNode.requestFocus();
  }

  void _playFeedbackSound() {
    if (_soundsEnabled) {
      unawaited(ref.read(soundPlayerProvider).playFeedback());
    }
  }

  void _onTap(
    BuildContext context,
    Offset localPosition,
    double cellSize,
    double offsetX,
    double offsetY,
  ) {
    final puzzle = widget.solveState.puzzle;
    final col = ((localPosition.dx - offsetX) / cellSize).floor();
    final row = ((localPosition.dy - offsetY) / cellSize).floor();

    if (row < 0 || row >= puzzle.height || col < 0 || col >= puzzle.width) {
      return;
    }

    if (_hapticsEnabled) HapticFeedback.selectionClick();
    final focus =
        ref.read(solveProvider(widget.puzzleId).notifier).tapCell(row, col);
    if (focus != null) widget.onGridFocusSelected?.call(focus);
    _requestFocus();
  }

  void _onLongPress(
    BuildContext context,
    Offset localPosition,
    double cellSize,
    double offsetX,
    double offsetY,
  ) {
    final puzzle = widget.solveState.puzzle;
    final col = ((localPosition.dx - offsetX) / cellSize).floor();
    final row = ((localPosition.dy - offsetY) / cellSize).floor();

    if (row < 0 || row >= puzzle.height || col < 0 || col >= puzzle.width) {
      return;
    }
    if (puzzle.grid.cell(row, col).isBlack) return;

    if (_hapticsEnabled) HapticFeedback.mediumImpact();

    // Focus is NOT moved here — only if the user actually picks an action
    // below. Moving it up-front meant dismissing the menu still jumped the
    // cursor and fired a full SolveState cascade for nothing (#126).
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final globalPos = box.localToGlobal(localPosition);

    showMenu<_CellAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPos.dx, globalPos.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(
          value: _CellAction.enterRebus,
          child: Text('Enter rebus'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _CellAction.checkLetter,
          child: Text('Check letter'),
        ),
        PopupMenuItem(value: _CellAction.checkWord, child: Text('Check word')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _CellAction.revealLetter,
          child: Text('Reveal letter'),
        ),
        PopupMenuItem(
          value: _CellAction.revealWord,
          child: Text('Reveal word'),
        ),
      ],
    ).then((action) {
      if (action == null) return;
      if (!mounted) return;
      if (!context.mounted) return;
      final notifier = ref.read(solveProvider(widget.puzzleId).notifier);
      // Now that an action is chosen, move focus to the long-pressed cell so
      // the check/reveal/rebus action applies there (same behavior as before,
      // just deferred past the dismiss case).
      final focus = notifier.tapCell(row, col);
      if (focus != null) widget.onGridFocusSelected?.call(focus);
      _requestFocus();
      switch (action) {
        case _CellAction.enterRebus:
          _showRebusDialog(context, row, col);
        case _CellAction.checkLetter:
          _vibrateIfIncorrect(notifier.checkCell());
        case _CellAction.checkWord:
          _vibrateIfIncorrect(notifier.checkWord());
        case _CellAction.revealLetter:
          notifier.revealCell();
        case _CellAction.revealWord:
          notifier.revealWord();
      }
    });
  }

  Future<void> _showRebusDialog(BuildContext context, int row, int col) async {
    final current = widget.solveState.progress.cell(row, col).letter;
    final wordComplete = await showRebusDialogForFocus(
      context: context,
      ref: ref,
      puzzleId: widget.puzzleId,
      currentLetter: current,
    );
    if (wordComplete != null) {
      _pulseIfWordComplete(wordComplete);
    }
    _requestFocus();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final notifier = ref.read(solveProvider(widget.puzzleId).notifier);

    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _playFeedbackSound();
      notifier.backspace();
      return KeyEventResult.handled;
    }

    // Esc opens the rebus dialog on the focused cell — matches NYT web's
    // shortcut. Repeats are ignored so holding Esc doesn't reopen on every
    // tick. Esc inside the dialog falls through to Flutter's default
    // AlertDialog "cancel" behavior.
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (event is KeyRepeatEvent) return KeyEventResult.handled;
      final focus = widget.solveState.focus;
      _showRebusDialog(context, focus.row, focus.col);
      return KeyEventResult.handled;
    }

    final state = widget.solveState;
    final currentFocus = state.focus;
    final shiftPressed = HardwareKeyboard.instance.isShiftPressed;

    final arrowMove = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => (0, 1, Direction.across),
      LogicalKeyboardKey.arrowLeft => (0, -1, Direction.across),
      LogicalKeyboardKey.arrowDown => (1, 0, Direction.down),
      LogicalKeyboardKey.arrowUp => (-1, 0, Direction.down),
      _ => null,
    };
    if (arrowMove != null) {
      if (shiftPressed) {
        final isForward = arrowMove.$1 + arrowMove.$2 > 0;
        final clue = isForward
            ? _findNextClue(state, currentFocus)
            : _findPreviousClue(state, currentFocus);
        final focus = clue == null ? null : notifier.focusClue(clue);
        if (focus != null) widget.onGridFocusSelected?.call(focus);
      } else {
        final focus = notifier.moveFocusTo(
              currentFocus.row + arrowMove.$1,
              currentFocus.col + arrowMove.$2,
              arrowMove.$3,
            ) ??
            notifier.moveFocusTo(
              currentFocus.row,
              currentFocus.col,
              arrowMove.$3,
            );
        if (focus != null) widget.onGridFocusSelected?.call(focus);
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.tab ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (event is KeyRepeatEvent) return KeyEventResult.handled;
      final clue = shiftPressed
          ? _findPreviousClue(state, currentFocus)
          : _findNextClue(state, currentFocus);
      final focus = clue == null ? null : notifier.focusClue(clue);
      if (focus != null) widget.onGridFocusSelected?.call(focus);
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && _letterRe.hasMatch(char)) {
      _playFeedbackSound();
      _pulseIfWordComplete(notifier.inputLetter(char));
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Clue? _findPreviousClue(SolveState state, FocusPosition currentFocus) {
    final clues = state.sortedClues;

    final currentClueIndex = clues.indexWhere(
      (clue) =>
          clue.direction == currentFocus.direction &&
          SolveState.cellInClue(currentFocus.row, currentFocus.col, clue),
    );

    if (currentClueIndex > 0) {
      return clues[currentClueIndex - 1];
    }
    if (clues.isNotEmpty) {
      return clues.last;
    }
    return null;
  }

  Clue? _findNextClue(SolveState state, FocusPosition currentFocus) {
    final clues = state.sortedClues;

    final currentClueIndex = clues.indexWhere(
      (clue) =>
          clue.direction == currentFocus.direction &&
          SolveState.cellInClue(currentFocus.row, currentFocus.col, clue),
    );

    if (currentClueIndex < clues.length - 1) {
      return clues[currentClueIndex + 1];
    }
    if (clues.isNotEmpty) {
      return clues.first;
    }
    return null;
  }

  void _pulseIfWordComplete(bool wordComplete) {
    if (wordComplete && _hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (wordComplete) {
      _playFeedbackSound();
    }
  }

  void _vibrateIfIncorrect(CheckResult result) {
    if (result.shouldVibrate && _hapticsEnabled) {
      HapticFeedback.vibrate();
    }
    if (result == CheckResult.allCorrect) {
      _playFeedbackSound();
    }
  }
}

enum _CellAction {
  enterRebus,
  checkLetter,
  checkWord,
  revealLetter,
  revealWord
}

/// Shared rebus dialog used by:
///   1. The long-press popup menu (see `_CrosswordGridInput._onLongPress`)
///   2. The "Rebus" key on the soft keyboard (see `solve_screen.dart`)
///   3. The `Esc` shortcut on a physical keyboard (see `_onKeyEvent`)
///
/// All three surfaces share one implementation so the rules (pre-fill,
/// formatter, max length, tap-outside-to-save, single-char round-trip)
/// stay in lockstep. See `docs/architecture/rebus-entry.md` §4.4.
///
/// Returns:
///   - `null` if the dialog was cancelled (Cancel button pressed).
///   - The `wordComplete` flag from `SolveNotifier.inputRebus` otherwise.
///     `false` includes the no-op case (empty input). Callers can use this
///     for haptics / sound on word completion.
Future<bool?> showRebusDialogForFocus({
  required BuildContext context,
  required WidgetRef ref,
  required String puzzleId,
  required String currentLetter,
}) async {
  // The latest text the user typed, captured via a callback from the
  // dialog. Used on barrier dismiss (matches NYT's "tap anywhere outside
  // to save your rebus"), where Navigator.pop() runs with no result.
  String latestText = currentLetter;

  final outcome = await showDialog<RebusOutcome>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => RebusDialog(
      initialText: currentLetter,
      onTextChanged: (text) => latestText = text,
    ),
  );

  // The controller is owned by RebusDialog's State and disposed in
  // dispose() — i.e. AFTER the route's tree finishes unmounting, not the
  // moment showDialog's future resolves. That's the fix for #105: the
  // previous design disposed the controller while the TextField subtree
  // was still in the tree mid-pop animation, tripping the framework's
  // `_dependents.isEmpty` assertion.

  final String? effective = switch (outcome) {
    RebusOutcomeCancelled() => null, // explicit Cancel — drop input
    RebusOutcomeEntered(:final text) => text, // Enter button / Enter key
    null => latestText, // barrier tap — save whatever the user typed
  };

  if (effective == null) return null;

  final notifier = ref.read(solveProvider(puzzleId).notifier);
  // inputRebus normalizes (uppercases, strips non-`[A-Z/]`, caps at 6) and
  // delegates back to inputLetter when the result is one character — so
  // the dialog is never a dead end for users who change their mind.
  return notifier.inputRebus(effective);
}

/// Dialog result. Sealed so the caller's switch is exhaustive.
///
/// Public + `@visibleForTesting` so the regression test in
/// `rebus_dialog_dispose_test.dart` can match on it without us having
/// to expose Riverpod scaffolding to drive the production entry point.
@visibleForTesting
sealed class RebusOutcome {
  const RebusOutcome();
}

@visibleForTesting
class RebusOutcomeCancelled extends RebusOutcome {
  const RebusOutcomeCancelled();
}

@visibleForTesting
class RebusOutcomeEntered extends RebusOutcome {
  const RebusOutcomeEntered(this.text);
  final String text;
}

/// Stateful dialog body that owns the TextEditingController. Disposing
/// the controller in [State.dispose] is what fixes #105 — the controller's
/// lifetime now matches the widget tree, so it can't outlive its TextField
/// dependents (or, equivalently, be torn down while they're still mounted).
///
/// Public + `@visibleForTesting` so the regression test can show the
/// dialog directly via `showDialog` without needing the full Riverpod
/// scope that `showRebusDialogForFocus` requires.
@visibleForTesting
class RebusDialog extends StatefulWidget {
  const RebusDialog({
    super.key,
    required this.initialText,
    required this.onTextChanged,
  });

  final String initialText;

  /// Fires on every text change so the caller can capture the latest
  /// value for the barrier-dismiss "save what you typed" flow without
  /// the State having to reach outside its own scope.
  final ValueChanged<String> onTextChanged;

  @override
  State<RebusDialog> createState() => _RebusDialogState();
}

class _RebusDialogState extends State<RebusDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_emitText);
  }

  void _emitText() => widget.onTextChanged(_controller.text);

  @override
  void dispose() {
    _controller.removeListener(_emitText);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter rebus'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        maxLength: SolveNotifier.rebusMaxLength,
        inputFormatters: [
          FilteringTextInputFormatter.allow(_rebusFilterRe),
        ],
        decoration: const InputDecoration(
          labelText: 'Cell answer',
          // Mention "/" so users discover bidirectional rebuses.
          hintText: 'Example: EST  (or PB/AU for bidirectional)',
        ),
        onSubmitted: (value) =>
            Navigator.of(context).pop(RebusOutcomeEntered(value)),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const RebusOutcomeCancelled()),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(RebusOutcomeEntered(_controller.text)),
          child: const Text('Enter'),
        ),
      ],
    );
  }
}
