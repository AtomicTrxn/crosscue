import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/settings/settings_providers.dart';
import '../../../../core/theme/crossword_theme.dart';

// ---------------------------------------------------------------------------
// Mock 5×5 grid data (hardcoded, never stored in Drift — topic-17 §7)
// ---------------------------------------------------------------------------

/// Each cell: null = black, String = solution letter.
const _grid = [
  ['C', 'R', 'O', 'S', 'S'],
  ['U', null, 'F', null, 'T'],
  ['E', 'D', 'I', 'T', 'S'],
  [null, null, 'C', null, 'A'],
  ['P', 'U', 'Z', 'Z', 'L'],
];


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0; // 0,1,2 = tutorial steps; 3 = done card
  int? _focusRow;
  int? _focusCol;
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
        // Auto-advance step 3 after 3 s (topic-17 §7)
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
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Skip + step dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  if (_step < 3)
                    _StepDots(current: _step, total: 3),
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            // Mock grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _MockGrid(
                  focusRow: _focusRow,
                  focusCol: _focusCol,
                  focusIsAcross: _focusIsAcross,
                  onCellTap: _onCellTap,
                ),
              ),
            ),

            // Bottom instruction card
            _InstructionCard(
              step: _step,
              step1Done: _step1Done,
              step2Done: _step2Done,
              onNext: _nextStep,
              onLetter: _onLetterTap,
              onImport: () async {
                final nav = GoRouter.of(context);
                await _complete();
                if (mounted) nav.push(Routes.import_);
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
// Step dots
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
          width: active ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock grid
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

                  Color bg;
                  if (isBlack) {
                    bg = xwTheme.gridBlack;
                  } else if (isFocused) {
                    bg = xwTheme.cellActive;
                  } else if (isWord) {
                    bg = xwTheme.wordHighlight;
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
                                child: Text(
                                  '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: xwTheme.cellText,
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

  bool _inActiveWord(int r, int c) {
    if (focusRow == null || focusCol == null) return false;
    if (focusIsAcross) return r == focusRow;
    return c == focusCol;
  }
}

// ---------------------------------------------------------------------------
// Instruction card
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: switch (step) {
        0 => _Step1Card(done: step1Done, onLetter: onLetter, onNext: onNext),
        1 => _Step2Card(done: step2Done, onNext: onNext),
        2 => _Step3Card(onNext: onNext),
        _ => _DoneCard(onImport: onImport, onLater: onLater),
      },
    );
  }
}

class _Step1Card extends StatelessWidget {
  const _Step1Card(
      {required this.done, required this.onLetter, required this.onNext});
  final bool done;
  final void Function(String) onLetter;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tap a cell, then type a letter',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Tap any white square to focus it. A word lights up. Type to fill it in.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        // Mini A–Z keyboard strip for the mock grid
        _LetterStrip(onLetter: onLetter),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: done ? onNext : null,
          child: const Text('Next →'),
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
        Text('Tap a focused cell to switch direction',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Tap the yellow cell again to toggle between Across and Down.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: done ? onNext : null,
          child: const Text('Next →'),
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
        Text('Get help any time',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Tap the ⋮ menu while solving to check your answers or reveal letters.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onNext, child: const Text('Next →')),
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
        Text("You're ready to solve!",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Import a .puz or .ipuz puzzle file to get started.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onImport,
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
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(l,
                    style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          );
        },
      ),
    );
  }
}
