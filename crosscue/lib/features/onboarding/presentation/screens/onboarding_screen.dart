import 'dart:async';

import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Mock 5×5 grid data (hardcoded, never stored in Drift)
// Spec grid (design/README.md §07):
//   Row 0: A  C  E  .  .    (. = black)
//   Row 1: L  O  .  T  E
//   Row 2: .  N  D  .  .
//   Row 3: G  E  .  P  S
//   Row 4: .  R  Y  E  .
// ---------------------------------------------------------------------------

/// Each cell: null = black, String = solution letter.
const _grid = [
  ['A', 'C', 'E', null, null],
  ['L', 'O', null, 'T', 'E'],
  [null, 'N', 'D', null, null],
  ['G', 'E', null, 'P', 'S'],
  [null, 'R', 'Y', 'E', null],
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0; // 0,1,2 = tutorial steps; 3 = done card
  // Start with cell (1,1) pre-focused (active cell = "O")
  int? _focusRow = 1;
  int? _focusCol = 1;
  bool _focusIsAcross = true;
  bool _step1Done = false;
  bool _step2Done = false;
  Timer? _step3Timer;

  @override
  void dispose() {
    _step3Timer?.cancel();
    super.dispose();
  }

  Future<void> _complete() async {
    await ref.read(appSettingsProvider).setHasSeenOnboarding(true);
    ref.invalidate(hasSeenOnboardingProvider);
  }

  void _onCellTap(int row, int col) {
    if (_grid[row][col] == null) return;

    setState(() {
      if (_step == 0) {
        _focusRow = row;
        _focusCol = col;
        _focusIsAcross = true;
        // Step 1 completes when user taps a cell — but we wait for a letter
      } else if (_step == 1) {
        if (_focusRow == row && _focusCol == col) {
          _focusIsAcross = !_focusIsAcross;
          if (!_step2Done) {
            _step2Done = true;
          }
        } else {
          _focusRow = row;
          _focusCol = col;
        }
      }
    });
  }

  void _onLetterTap(String letter) {
    if (_step == 0 && _focusRow != null && !_step1Done) {
      setState(() => _step1Done = true);
    }
  }

  void _nextStep() {
    if (_step == 2) {
      // Start 3-second auto-advance or user tapped Next
      setState(() => _step = 3);
      return;
    }
    if (_step == 3) return;
    setState(() {
      _step++;
      if (_step == 2) {
        // Auto-advance step 3 after 3 s
        _step3Timer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _step = 3);
        });
      }
    });
  }

  void _skip() async {
    final nav = GoRouter.of(context);
    await _complete();
    if (mounted) nav.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrosscueColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CrosscueSpacing.screenH,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  if (_step < 3) _StepDots(current: _step, total: 3),
                  // White translucent text on navy background
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.65),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CrosscueSpacing.screenH,
                  24,
                  CrosscueSpacing.screenH,
                  16,
                ),
                child: _MockGrid(
                  focusRow: _focusRow,
                  focusCol: _focusCol,
                  focusIsAcross: _focusIsAcross,
                  onCellTap: _onCellTap,
                ),
              ),
            ),
            _InstructionCard(
              step: _step,
              step1Done: _step1Done,
              step2Done: _step2Done,
              onNext: _nextStep,
              onLetter: _onLetterTap,
              onImport: () async {
                final nav = GoRouter.of(context);
                await _complete();
                if (mounted) nav.go(Routes.import_);
              },
              onLater: () async {
                final nav = GoRouter.of(context);
                await _complete();
                if (mounted) nav.go(Routes.home);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step dots — spec: 8dp circles rgba(255,255,255,0.3), active: 20×8dp #FDD835
// ---------------------------------------------------------------------------

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 8, // spec: active 20dp pill
          height: 8,
          decoration: BoxDecoration(
            // Active: #FDD835 yellow pill; inactive: white 30% on navy bg
            color: active
                ? CrosscueColors.cellActiveLight
                : Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock grid — pre-filled letters and proper highlights
// ---------------------------------------------------------------------------

class _MockGrid extends StatelessWidget {
  const _MockGrid({
    required this.focusRow,
    required this.focusCol,
    required this.focusIsAcross,
    required this.onCellTap,
  });

  final int? focusRow;
  final int? focusCol;
  final bool focusIsAcross;
  final void Function(int row, int col) onCellTap;

  @override
  Widget build(BuildContext context) {
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: List.generate(5, (r) {
            return Expanded(
              child: Row(
                children: List.generate(5, (c) {
                  final letter = _grid[r][c];
                  final isBlack = letter == null;
                  final isFocused = focusRow == r && focusCol == c;
                  final isWord = !isBlack && _inActiveWord(r, c);
                  final isCross =
                      !isBlack && !isFocused && !isWord && _inCrossWord(r, c);

                  Color bg;
                  if (isBlack) {
                    bg = xwTheme.gridBlack;
                  } else if (isFocused) {
                    bg = xwTheme.cellActive;
                  } else if (isWord) {
                    bg = xwTheme.wordHighlight;
                  } else if (isCross) {
                    bg = xwTheme.crossHighlight;
                  } else {
                    bg = xwTheme.gridEmpty;
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onCellTap(r, c),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: xwTheme.gridBorder),
                        ),
                        child: isBlack
                            ? null
                            : Center(
                                child: FittedBox(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: xwTheme.cellText,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Returns true if (r,c) is in the active word (respects black cell boundaries).
  bool _inActiveWord(int r, int c) {
    if (focusRow == null || focusCol == null) return false;
    if (focusIsAcross) {
      return r == focusRow && _inAcrossWordBounds(focusRow!, focusCol!, c);
    } else {
      return c == focusCol && _inDownWordBounds(focusRow!, focusCol!, r);
    }
  }

  // Returns true if (r,c) is in the cross word through the focus cell.
  bool _inCrossWord(int r, int c) {
    if (focusRow == null || focusCol == null) return false;
    if (focusIsAcross) {
      // Cross = down word through (focusRow, focusCol)
      return c == focusCol && _inDownWordBounds(focusRow!, focusCol!, r);
    } else {
      // Cross = across word through (focusRow, focusCol)
      return r == focusRow && _inAcrossWordBounds(focusRow!, focusCol!, c);
    }
  }

  /// Is column [testC] within the across word that contains column [anchorC] in row [r]?
  bool _inAcrossWordBounds(int r, int anchorC, int testC) {
    // Walk left to find word start
    int start = anchorC;
    while (start > 0 && _grid[r][start - 1] != null) {
      start--;
    }
    // Walk right to find word end
    int end = anchorC;
    while (end < 4 && _grid[r][end + 1] != null) {
      end++;
    }
    return testC >= start && testC <= end;
  }

  /// Is row [testR] within the down word that contains row [anchorR] in column [c]?
  bool _inDownWordBounds(int anchorR, int c, int testR) {
    int start = anchorR;
    while (start > 0 && _grid[start - 1][c] != null) {
      start--;
    }
    int end = anchorR;
    while (end < 4 && _grid[end + 1][c] != null) {
      end++;
    }
    return testR >= start && testR <= end;
  }
}

// ---------------------------------------------------------------------------
// Instruction card — white sheet with drag handle, step label, content
// ---------------------------------------------------------------------------

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.step,
    required this.step1Done,
    required this.step2Done,
    required this.onNext,
    required this.onLetter,
    required this.onImport,
    required this.onLater,
  });

  final int step;
  final bool step1Done;
  final bool step2Done;
  final VoidCallback onNext;
  final void Function(String) onLetter;
  final VoidCallback onImport;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CrosscueSpacing.sheetRadius),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        12,
        CrosscueSpacing.screenH,
        24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle — 36×4dp #E8E8E8
          Container(
            width: CrosscueSpacing.dragHandleW,
            height: CrosscueSpacing.dragHandleH,
            decoration: BoxDecoration(
              color: CrosscueColors.dividerLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          switch (step) {
            0 => _Step1Card(
                done: step1Done,
                onLetter: onLetter,
                onNext: onNext,
              ),
            1 => _Step2Card(done: step2Done, onNext: onNext),
            2 => _Step3Card(onNext: onNext),
            _ => _DoneCard(onImport: onImport, onLater: onLater),
          },
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared step card heading
// ---------------------------------------------------------------------------

class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.stepLabel,
    required this.title,
    required this.body,
  });

  final String stepLabel;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step label: 11px w600 #1565C0 UPPERCASE letterSpacing 0.08em
        Text(
          stepLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CrosscueColors.primary,
            letterSpacing: 0.88, // 0.08em × 11px
          ),
        ),
        const SizedBox(height: 6),
        // Title: 20px w700 #1A1A1A lineHeight 1.25
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CrosscueColors.onSurface1Light,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        // Body: 14px #555555 lineHeight 1.5
        Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            color: CrosscueColors.onSurface2Light,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step cards
// ---------------------------------------------------------------------------

class _Step1Card extends StatelessWidget {
  const _Step1Card({
    required this.done,
    required this.onLetter,
    required this.onNext,
  });
  final bool done;
  final void Function(String) onLetter;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeading(
          stepLabel: 'STEP 1',
          title: 'Tap a cell to focus it',
          body:
              'Then type a letter. The cursor advances to the next empty cell automatically.',
        ),
        const SizedBox(height: 20),
        // Mini A–Z keyboard strip for the mock grid
        _LetterStrip(onLetter: onLetter),
        const SizedBox(height: 12),
        // CTA: 48dp height, 10dp radius
        FilledButton(
          onPressed: done ? onNext : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(CrosscueSpacing.buttonRadiusLg),
            ),
          ),
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _Step2Card extends StatelessWidget {
  const _Step2Card({required this.done, required this.onNext});
  final bool done;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeading(
          stepLabel: 'STEP 2',
          title: 'Tap the focused cell again',
          body: 'This switches direction between Across and Down.',
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: done ? onNext : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(CrosscueSpacing.buttonRadiusLg),
            ),
          ),
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _Step3Card extends StatelessWidget {
  const _Step3Card({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeading(
          stepLabel: 'STEP 3',
          title: 'Use Check or Reveal anytime',
          body: 'Find them in the ⋮ menu while solving.',
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(CrosscueSpacing.buttonRadiusLg),
            ),
          ),
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.onImport, required this.onLater});
  final VoidCallback onImport;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "You're ready to solve!",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Import a puzzle file to get started.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onImport,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(CrosscueSpacing.buttonRadiusLg),
            ),
          ),
          child: const Text('Import your first puzzle'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onLater, child: const Text('Maybe later')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Simple A–Z letter strip for step 1
// ---------------------------------------------------------------------------

class _LetterStrip extends StatelessWidget {
  const _LetterStrip({required this.onLetter});
  final void Function(String) onLetter;

  @override
  Widget build(BuildContext context) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: letters.length,
        itemBuilder: (_, i) {
          final l = letters[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => onLetter(l),
              child: Container(
                width: 32,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(CrosscueSpacing.buttonRadius),
                ),
                child: Text(l, style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          );
        },
      ),
    );
  }
}
