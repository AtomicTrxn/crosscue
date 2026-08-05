import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/puzzle_size_bucket.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/check_result.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/models/solve_errors.dart';
import 'package:crosscue/features/solve/domain/services/solve_focus_navigator.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/widgets/clue_columns_panel.dart';
import 'package:crosscue/features/solve/presentation/widgets/clue_list_panel.dart';
import 'package:crosscue/features/solve/presentation/widgets/clue_panel.dart';
import 'package:crosscue/features/solve/presentation/widgets/completion_sheet.dart';
import 'package:crosscue/features/solve/presentation/widgets/crossword_grid.dart'
    show CrosswordGrid, showRebusDialogForFocus;
import 'package:crosscue/features/solve/presentation/widgets/crossword_keyboard.dart';
import 'package:crosscue/features/solve/presentation/widgets/keyboard_hidden_controls.dart';
import 'package:crosscue/features/solve/presentation/widgets/pause_overlay.dart';
import 'package:crosscue/features/solve/presentation/widgets/solve_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';

class SolveScreen extends ConsumerStatefulWidget {
  const SolveScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen>
    with WidgetsBindingObserver {
  late final ConfettiController _confettiController;
  String? _selectorPuzzleId;
  Clue? _selectedActiveClue;
  Clue? _selectedCrossClue;
  bool _hapticsEnabled = true;
  bool _soundsEnabled = false;

  /// Bottom space reserved in the clue panel/list when
  /// [KeyboardHiddenControls] is floating over that same corner — tall
  /// enough for its single row of 40dp buttons plus its bottom offset
  /// (#298; the cluster is a horizontal `Row` now, not a stacked `Column`,
  /// so it needs far less clearance than before).
  static const _hiddenControlsReserve = 70.0;

  /// Material's tablet breakpoint (shortest side, orientation-independent —
  /// unlike `constraints.maxWidth`, which flips with rotation). Landscape
  /// tablets get to keep the two-column [ClueColumnsPanel] permanently (see
  /// [_buildLandscapeBody]); phones don't have the width to spare once the
  /// keyboard is also on screen, so they keep toggling to the compact
  /// [CluePanel] bar as before.
  static const _kTabletShortestSide = 600.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
    ref.listenManual(solveProvider(widget.puzzleId), _onSolveStateChanged);
    ref.listenManual(
      hapticsEnabledProvider,
      (_, next) => _hapticsEnabled = next,
      fireImmediately: true,
    );
    ref.listenManual(
      soundsEnabledProvider,
      (_, next) => _soundsEnabled = next,
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    // The terminal-completion backstop and the in-progress elapsed flush now
    // live in SolveNotifier.build's onDispose (see SolveNotifier.flushOnDispose),
    // so the guarantee no longer depends on the widget teardown caching
    // `ref`-derived state. Still caught by integration_test/seed_and_solve_test.dart.
    _confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Solve-screen lifecycle observer — one of exactly two observers in the
  /// app.
  ///
  /// Responsibility split:
  ///   - This observer handles `paused` / `hidden` (auto-pause the puzzle
  ///     timer) and `detached` (flush any pending save).
  ///   - The app-level [`_CrosshareLifecycleObserver`] in `app.dart`
  ///     handles `resumed` (retrigger Crosshare auto-download).
  ///
  /// Do not add a third observer elsewhere. See the policy comment on
  /// `_CrosshareLifecycleObserver` and the guard test at
  /// `test/architecture/lifecycle_observers_test.dart`.
  ///
  /// Auto-resume from pause is handled by the overlay tap, see
  /// [_PauseOverlay].
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.hidden) {
      ref.read(solveProvider(widget.puzzleId).notifier).pause();
    } else if (lifecycleState == AppLifecycleState.detached) {
      unawaited(
        ref.read(solveProvider(widget.puzzleId).notifier).flushPendingSave(),
      );
    }
  }

  void _playFeedbackSound({bool? soundsEnabled}) {
    if (soundsEnabled ?? _soundsEnabled) {
      unawaited(ref.read(soundPlayerProvider).playFeedback());
    }
  }

  void _maybeShowCompletionSheet(SolveState solveState) {
    final isComplete =
        solveState.status == PuzzleStatus.solved ||
        solveState.status == PuzzleStatus.solvedWithHelp ||
        solveState.status == PuzzleStatus.solvedWithReveal ||
        solveState.status == PuzzleStatus.revealed;
    if (!isComplete || solveState.completionSheetShown) return;

    // Canonical "sheet shown" flag lives in SolveState so it survives widget
    // recreation (backgrounding, hot reload) and can't re-trigger the sheet.
    ref
        .read(solveProvider(widget.puzzleId).notifier)
        .markCompletionSheetShown();

    // Push the freshly-completed solve to other devices. Fired here (once per
    // completion, gated by the flag above) rather than in SolveNotifier so the
    // notifier's unit tests don't force orchestrator/DB construction. No-op
    // unless sync is enabled and signed in (the orchestrator self-guards).
    unawaited(ref.read(syncOrchestratorProvider).syncNow());

    // (The Home/Lock-screen widget refreshes reactively in app.dart when
    // statsData is invalidated after the completion is persisted — doing it
    // here would race the DB write and push a stale streak/solve-state.)

    if (_hapticsEnabled) {
      unawaited(_pulseCompletionHaptics());
    }
    _playFeedbackSound();

    // Wave flash (500ms) → confetti (800ms) → sheet slide up (350ms)
    final animationsDisabled = MediaQuery.of(context).disableAnimations;

    Future<void> showSheet() async {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        // Deep navy overlay (rgba(10,42,110,0.88))
        barrierColor: CrosscueColors.barrierDeepNavy,
        builder: (ctx) => CompletionSheet(
          solveState: solveState,
          onViewGrid: () => Navigator.of(ctx).pop(),
          onNextPuzzle: () {
            Navigator.of(ctx).pop();
            if (mounted) context.go(Routes.home);
          },
          onResetPuzzle: () {
            Navigator.of(ctx).pop();
            if (!mounted) return;
            // resetPuzzle clears completionSheetShown in SolveState.
            ref.read(solveProvider(widget.puzzleId).notifier).resetPuzzle();
          },
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (animationsDisabled) {
        await showSheet();
        return;
      }
      // Wait for grid wave flash (500ms), then run confetti (800ms)
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _confettiController.play();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await showSheet();
    });
  }

  void _onSolveStateChanged(
    AsyncValue<SolveState>? previous,
    AsyncValue<SolveState> next,
  ) {
    next.whenData((solveState) {
      // The "sheet shown" flag now lives in SolveState and is reset by
      // resetPuzzle, so there's no widget-side flag to clear here.
      _maybeShowCompletionSheet(solveState);
      _syncClueSelectors(solveState);
    });
  }

  void _syncClueSelectors(SolveState solveState) {
    final nextActiveClue = solveState.activeClue;
    final nextCrossClue = solveState.crossClue;
    final puzzleChanged = _selectorPuzzleId != solveState.puzzle.id;
    final activeChanged = !_sameClue(_selectedActiveClue, nextActiveClue);
    final crossChanged = !_sameClue(_selectedCrossClue, nextCrossClue);
    if (!puzzleChanged && !activeChanged && !crossChanged) return;

    _selectorPuzzleId = solveState.puzzle.id;
    if (!mounted) return;
    setState(() {
      _selectedActiveClue = nextActiveClue;
      _selectedCrossClue = nextCrossClue;
    });
  }

  bool _sameClue(Clue? a, Clue? b) {
    return a?.number == b?.number && a?.direction == b?.direction;
  }

  void _setSelectorsFromFocus(SolveState solveState, FocusPosition focus) {
    setState(() {
      _selectedActiveClue = _clueForFocus(solveState, focus, focus.direction);
      _selectedCrossClue = _clueForFocus(
        solveState,
        focus,
        _oppositeDirection(focus.direction),
      );
    });
  }

  void _setSelectorsFromClue(SolveState solveState, Clue clue) {
    final focus = SolveFocusNavigator.focusForClue(solveState, clue);
    setState(() {
      _selectedActiveClue = clue;
      _selectedCrossClue = _clueForFocus(
        solveState,
        focus,
        _oppositeDirection(clue.direction),
      );
    });
  }

  /// Shared handler for selecting a clue from the active-clue bar or the list:
  /// updates the selectors and moves grid focus to the clue.
  void _onClueSelected(SolveState solveState, Clue clue, bool hapticsEnabled) {
    if (hapticsEnabled) HapticFeedback.selectionClick();
    _setSelectorsFromClue(solveState, clue);
    ref.read(solveProvider(widget.puzzleId).notifier).focusClue(clue);
  }

  /// Steps to the previous (-1) / next (+1) clue in the active direction,
  /// wrapping. Backs the active-clue bar's ‹ › arrows.
  void _stepClue(
    SolveState solveState,
    Clue? active,
    int delta,
    bool hapticsEnabled,
  ) {
    if (active == null) return;
    final clues =
        solveState.puzzle.clues
            .where((c) => c.direction == active.direction)
            .toList()
          ..sort((a, b) => a.number.compareTo(b.number));
    if (clues.isEmpty) return;
    final i = clues.indexWhere(
      (c) => c.number == active.number && c.direction == active.direction,
    );
    if (i < 0) return;
    final next = clues[(i + delta + clues.length) % clues.length];
    _onClueSelected(solveState, next, hapticsEnabled);
  }

  Clue? _clueForFocus(
    SolveState solveState,
    FocusPosition focus,
    Direction direction,
  ) {
    for (final clue in solveState.puzzle.clues) {
      if (clue.direction == direction &&
          SolveState.cellInClue(focus.row, focus.col, clue)) {
        return clue;
      }
    }
    return null;
  }

  Direction _oppositeDirection(Direction direction) {
    return direction == Direction.across ? Direction.down : Direction.across;
  }

  @override
  Widget build(BuildContext context) {
    final solveAsync = ref.watch(solveProvider(widget.puzzleId));
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);
    final soundsEnabled = ref.watch(soundsEnabledProvider);
    final showOnScreenKeyboard = ref.watch(showOnScreenKeyboardProvider);

    return solveAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) {
        final message = switch (e) {
          PuzzleNotFoundError() =>
            'This puzzle no longer exists. It may have been deleted.',
          SolveSessionLoadError(:final cause) =>
            'Could not load session: $cause',
          _ => 'Could not load puzzle. Please go back and try again.',
        };
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.home),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (solveState) {
        final puzzle = solveState.puzzle;
        final selectedActiveClue = _selectedActiveClue ?? solveState.activeClue;
        final selectedCrossClue = _selectedCrossClue ?? solveState.crossClue;
        final isComplete =
            solveState.status == PuzzleStatus.solved ||
            solveState.status == PuzzleStatus.solvedWithHelp ||
            solveState.status == PuzzleStatus.solvedWithReveal ||
            solveState.status == PuzzleStatus.revealed;

        return PopScope(
          // When the solve screen is the navigation root (opened straight from
          // the widget deep link), there's nothing to pop to. Let the system
          // back gesture / Android hardware back route to Home instead of
          // trapping the user — mirrors the AppBar back button (#114).
          canPop: context.canPop(),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.go(Routes.home);
          },
          child: Scaffold(
            // Keep layout stable when the soft keyboard appears.
            // The hidden TextField driving input is off-screen at (-200,-200);
            // the grid never reflects when the OS keyboard slides up.
            resizeToAvoidBottomInset: false,
            appBar: SolveAppBar(
              puzzleId: widget.puzzleId,
              title: puzzle.metadata.title,
              solveState: solveState,
              isComplete: isComplete,
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final orientation = MediaQuery.of(context).orientation;
                final body = orientation == Orientation.landscape
                    ? _buildLandscapeBody(
                        constraints: constraints,
                        solveState: solveState,
                        selectedActiveClue: selectedActiveClue,
                        selectedCrossClue: selectedCrossClue,
                        isComplete: isComplete,
                        hapticsEnabled: hapticsEnabled,
                        soundsEnabled: soundsEnabled,
                        showOnScreenKeyboard: showOnScreenKeyboard,
                      )
                    : _buildPortraitBody(
                        constraints: constraints,
                        solveState: solveState,
                        selectedActiveClue: selectedActiveClue,
                        selectedCrossClue: selectedCrossClue,
                        isComplete: isComplete,
                        hapticsEnabled: hapticsEnabled,
                        soundsEnabled: soundsEnabled,
                        showOnScreenKeyboard: showOnScreenKeyboard,
                      );

                return Stack(
                  children: [
                    body,

                    // Floating show-keyboard/Rebus cluster — the only way
                    // back to the keyboard once it's hidden, now that the
                    // old Settings toggle and app-bar escape hatch are gone
                    // (#298). The right/bottom offsets deliberately match
                    // CrosswordKeyboard's own Container padding
                    // (EdgeInsets.fromLTRB(4, 6, 4, 8) — right:4, bottom:8)
                    // so this cluster lands in essentially the same spot as
                    // the Rebus/hide-keyboard keys it replaces when the
                    // keyboard is visible — toggling reads as those two
                    // buttons staying in place, not jumping corners.
                    // MediaQuery insets are still added on top (both bottom
                    // and right, since a rotated notch/Dynamic Island in
                    // landscape encroaches from the side) rather than
                    // nesting in a SafeArea, matching how the landscape body
                    // already handles this.
                    if (!isComplete && !showOnScreenKeyboard)
                      Positioned(
                        right: 4 + MediaQuery.of(context).padding.right,
                        bottom: 8 + MediaQuery.of(context).padding.bottom,
                        child: KeyboardHiddenControls(
                          onShowKeyboard: () => ref
                              .read(showOnScreenKeyboardProvider.notifier)
                              .toggle(),
                          onRebus: () => _openRebusDialog(
                            context: context,
                            solveState: solveState,
                            hapticsEnabled: hapticsEnabled,
                            soundsEnabled: soundsEnabled,
                          ),
                        ),
                      ),

                    // Pause overlay — shown when paused and puzzle not yet complete
                    if (solveState.isPaused && !isComplete)
                      PauseOverlay(
                        onResume: () => ref
                            .read(solveProvider(widget.puzzleId).notifier)
                            .resume(),
                      ),

                    // Confetti overlay — triggered on puzzle complete
                    if (!MediaQuery.of(context).disableAnimations)
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          numberOfParticles: 20,
                          gravity: 0.3,
                          colors: CrosscueColors.confettiPalette,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Portrait layout: grid on top (capped at 55% of body height so CluePanel
  /// and keyboard always have room), the active/cross clue bar, then the
  /// on-screen keyboard (if enabled).
  Widget _buildPortraitBody({
    required BoxConstraints constraints,
    required SolveState solveState,
    required Clue? selectedActiveClue,
    required Clue? selectedCrossClue,
    required bool isComplete,
    required bool hapticsEnabled,
    required bool soundsEnabled,
    required bool showOnScreenKeyboard,
  }) {
    final isTablet =
        MediaQuery.of(context).size.shortestSide >= _kTabletShortestSide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CrosswordGrid's internal LayoutBuilder sizes cells by
        // min(width/cols, height/rows) so it renders correctly within any
        // tight height bound.
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.55),
          child: CrosswordGrid(
            puzzleId: widget.puzzleId,
            solveState: solveState,
            onGridFocusSelected: (focus) =>
                _setSelectorsFromFocus(solveState, focus),
          ),
        ),

        // Clue display — see _buildClueArea (#298). Expanded with no flex
        // competitors so it takes exactly the space between grid and
        // keyboard, leaving zero free space that could float the keyboard
        // up. Phones keep the compact bar even with the keyboard hidden — a
        // portrait phone doesn't have the width for a scrollable list to
        // earn its keep. Tablets get the same permanent two-column
        // [ClueColumnsPanel] as landscape (#298 follow-up) — a portrait
        // tablet has the width for two columns just as much as landscape
        // does, so there's no reason to collapse to a single list or the
        // compact bar here either.
        Expanded(
          child: _buildClueArea(
            solveState: solveState,
            selectedActiveClue: selectedActiveClue,
            selectedCrossClue: selectedCrossClue,
            isComplete: isComplete,
            hapticsEnabled: hapticsEnabled,
            showOnScreenKeyboard: showOnScreenKeyboard,
            twoColumn: isTablet,
            forceFullClueArea: isTablet,
            forceCompactClueArea: !isTablet,
          ),
        ),

        if (!isComplete && showOnScreenKeyboard)
          _buildKeyboard(
            solveState: solveState,
            hapticsEnabled: hapticsEnabled,
            soundsEnabled: soundsEnabled,
          ),

        // Bottom safe-area padding
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  /// Landscape layout (issue: keyboard/landscape feedback) — the grid hugs
  /// the left edge, sized by its own aspect ratio so it fills the full
  /// available height instead of centering in a wide box; the freed-up width
  /// goes to a clue list on the right so many clues are visible at once
  /// (matches what a Bluetooth-keyboard tablet solver asked for). The active
  /// on-screen keyboard, if shown, still spans the bottom.
  Widget _buildLandscapeBody({
    required BoxConstraints constraints,
    required SolveState solveState,
    required Clue? selectedActiveClue,
    required Clue? selectedCrossClue,
    required bool isComplete,
    required bool hapticsEnabled,
    required bool soundsEnabled,
    required bool showOnScreenKeyboard,
  }) {
    final puzzle = solveState.puzzle;
    final isTablet =
        MediaQuery.of(context).size.shortestSide >= _kTabletShortestSide;

    // Left/right only — top is already covered by the AppBar and bottom is
    // handled by the manual padding below (matches the portrait layout's
    // approach; a full SafeArea here would double that bottom padding). This
    // matters in landscape specifically: a rotated notch/Dynamic Island
    // encroaches from the *side*, not the top.
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, rowConstraints) {
                    final availableHeight = rowConstraints.maxHeight;
                    final aspectWidth =
                        availableHeight * puzzle.width / puzzle.height;
                    // Cap so the clue list always keeps meaningful room, even
                    // for a near-square puzzle in a narrow landscape window.
                    final gridWidth = math.min(
                      aspectWidth,
                      constraints.maxWidth * 0.6,
                    );
                    return SizedBox(
                      width: gridWidth,
                      child: CrosswordGrid(
                        puzzleId: widget.puzzleId,
                        solveState: solveState,
                        onGridFocusSelected: (focus) =>
                            _setSelectorsFromFocus(solveState, focus),
                      ),
                    );
                  },
                ),
                // Same compact-bar-vs-full-list toggle as portrait (#298) —
                // a phone-width landscape window doesn't have room for both
                // the CluePanel bar and a scrollable list above the keyboard
                // at once, so only one shows at a time here too, exactly as
                // it already did in portrait.
                Expanded(
                  child: _buildClueArea(
                    solveState: solveState,
                    selectedActiveClue: selectedActiveClue,
                    selectedCrossClue: selectedCrossClue,
                    isComplete: isComplete,
                    hapticsEnabled: hapticsEnabled,
                    showOnScreenKeyboard: showOnScreenKeyboard,
                    twoColumn: true,
                    forceFullClueArea: isTablet,
                  ),
                ),
              ],
            ),
          ),

          if (!isComplete && showOnScreenKeyboard)
            _buildKeyboard(
              solveState: solveState,
              hapticsEnabled: hapticsEnabled,
              soundsEnabled: soundsEnabled,
            ),

          // Bottom safe-area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Clue display, shared by portrait and landscape — toggles between the
  /// compact active/cross [CluePanel] bar (keyboard visible — screen space
  /// is tight, and the ‹ › arrows are the primary way to move between
  /// clues) and a full clue list (keyboard hidden — the freed-up room is
  /// put to use showing every clue at once, tap-to-jump). Landscape used to
  /// show the CluePanel bar and a list simultaneously, but a phone-width
  /// landscape window doesn't have room for both plus the keyboard without
  /// clipping (#298) — this makes the behavior identical in both
  /// orientations instead. Caller wraps the result in `Expanded`.
  ///
  /// [twoColumn] picks which full-list widget shows when the keyboard is
  /// hidden: tablets (both orientations) have the width for
  /// [ClueColumnsPanel] — independently scrollable Across/Down columns that
  /// keep the active clue *and* its cross clue both visible at once,
  /// reviving the app's original two-column clue panel (removed in #154 for
  /// the compact bar). Phones don't have the width for two columns, so they
  /// keep the single-list [ClueListPanel] (landscape) or, per
  /// [forceCompactClueArea] below, never reach the list at all (portrait).
  ///
  /// [forceFullClueArea] keeps that full-list widget showing even while the
  /// keyboard is visible — set for tablets (both orientations), which have
  /// room for [ClueColumnsPanel] plus the keyboard at once and shouldn't
  /// collapse to the compact [CluePanel] bar just because the keyboard is up.
  ///
  /// [forceCompactClueArea] is the opposite override: keeps the compact
  /// [CluePanel] bar showing even while the keyboard is hidden — set for
  /// portrait phones, which don't have the width to make a scrollable list
  /// worthwhile the way a tablet's two-column view does. Landscape phones
  /// leave this false and keep the prior toggle-to-list-when-hidden
  /// behavior. The two overrides are keyed off the same tablet/phone check
  /// and never both apply to the same call site.
  Widget _buildClueArea({
    required SolveState solveState,
    required Clue? selectedActiveClue,
    required Clue? selectedCrossClue,
    required bool isComplete,
    required bool hapticsEnabled,
    required bool showOnScreenKeyboard,
    required bool twoColumn,
    bool forceFullClueArea = false,
    bool forceCompactClueArea = false,
  }) {
    assert(!(forceFullClueArea && forceCompactClueArea));
    if ((!showOnScreenKeyboard && !forceCompactClueArea) || forceFullClueArea) {
      return Padding(
        // Reserves room at the bottom so the floating KeyboardHiddenControls
        // cluster (which shares this same bottom-right corner) never sits on
        // top of live clue text (#298) — it floats in genuinely empty space
        // instead. Matches the cluster's own render condition exactly: the
        // cluster only ever renders when the keyboard is hidden, regardless
        // of forceFullClueArea, so the reserve stays tied to that.
        padding: EdgeInsets.only(
          bottom: !isComplete && !showOnScreenKeyboard
              ? _hiddenControlsReserve
              : 0,
        ),
        child: twoColumn
            ? ClueColumnsPanel(
                clues: solveState.sortedClues,
                activeClue: selectedActiveClue,
                crossClue: selectedCrossClue,
                solveState: solveState,
                onSelectClue: (clue) =>
                    _onClueSelected(solveState, clue, hapticsEnabled),
              )
            : ClueListPanel(
                clues: solveState.sortedClues,
                activeClue: selectedActiveClue,
                crossClue: selectedCrossClue,
                solveState: solveState,
                onSelectClue: (clue) =>
                    _onClueSelected(solveState, clue, hapticsEnabled),
              ),
      );
    }

    return CluePanel(
      activeClue: selectedActiveClue,
      crossClue: selectedCrossClue,
      onSelectClue: (clue) => _onClueSelected(solveState, clue, hapticsEnabled),
      onPrev: () =>
          _stepClue(solveState, selectedActiveClue, -1, hapticsEnabled),
      onNext: () =>
          _stepClue(solveState, selectedActiveClue, 1, hapticsEnabled),
    );
  }

  /// Custom QWERTY keyboard — shared by portrait and landscape layouts.
  Widget _buildKeyboard({
    required SolveState solveState,
    required bool hapticsEnabled,
    required bool soundsEnabled,
  }) {
    final puzzle = solveState.puzzle;
    return CrosswordKeyboard(
      isSmallPuzzle: puzzle.sizeBucket == PuzzleSizeBucket.mini,
      hapticsEnabled: hapticsEnabled,
      soundsEnabled: soundsEnabled,
      onFeedbackSound: () => _playFeedbackSound(soundsEnabled: soundsEnabled),
      onLetter: (l) {
        final wordComplete = ref
            .read(solveProvider(widget.puzzleId).notifier)
            .inputLetter(l);
        if (wordComplete && hapticsEnabled) {
          HapticFeedback.mediumImpact();
        }
        if (wordComplete) {
          _playFeedbackSound(soundsEnabled: soundsEnabled);
        }
      },
      onBackspace: () =>
          ref.read(solveProvider(widget.puzzleId).notifier).backspace(),
      onCheckWord: () {
        final result = ref
            .read(solveProvider(widget.puzzleId).notifier)
            .checkWord();
        if (result.shouldVibrate && hapticsEnabled) {
          HapticFeedback.vibrate();
        }
        if (result == CheckResult.allCorrect) {
          _playFeedbackSound(soundsEnabled: soundsEnabled);
        }
      },
      onRebus: () => _openRebusDialog(
        context: context,
        solveState: solveState,
        hapticsEnabled: hapticsEnabled,
        soundsEnabled: soundsEnabled,
      ),
      onHideKeyboard: () =>
          ref.read(showOnScreenKeyboardProvider.notifier).toggle(),
    );
  }

  /// Opens the rebus entry dialog for the currently focused cell.
  /// Called from the soft keyboard's "Rebus" key. The long-press menu has
  /// its own entry point inside [CrosswordGrid].
  void _openRebusDialog({
    required BuildContext context,
    required SolveState solveState,
    required bool hapticsEnabled,
    required bool soundsEnabled,
  }) {
    if (hapticsEnabled) HapticFeedback.lightImpact();
    final focus = solveState.focus;
    final currentLetter = solveState.progress.cell(focus.row, focus.col).letter;
    unawaited(
      showRebusDialogForFocus(
        context: context,
        ref: ref,
        puzzleId: widget.puzzleId,
        currentLetter: currentLetter,
      ).then((wordComplete) {
        if (wordComplete == true) {
          if (hapticsEnabled) HapticFeedback.mediumImpact();
          _playFeedbackSound(soundsEnabled: soundsEnabled);
        }
      }),
    );
  }

  Future<void> _pulseCompletionHaptics() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(
        pattern: const [0, 35, 55, 55, 65, 80],
        intensities: const [90, 0, 160, 0, 255, 0],
      );
    } else {
      await HapticFeedback.heavyImpact();
    }
  }
}
