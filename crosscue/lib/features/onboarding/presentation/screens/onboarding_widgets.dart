part of 'onboarding_screen.dart';

// ---------------------------------------------------------------------------
// Background grid watermark — barely-there crossword pattern that reinforces
// the app's identity without drawing attention away from the foreground.
// ---------------------------------------------------------------------------

class _GridWatermark extends StatelessWidget {
  const _GridWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridWatermarkPainter(),
      ),
    );
  }
}

class _GridWatermarkPainter extends CustomPainter {
  static const double _cell = 48;
  static final Paint _stroke = Paint()
    ..color = Colors.white.withValues(alpha: 0.035)
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Confine the watermark to the upper navy area so it doesn't bleed under
    // the instruction sheet.
    final upper = Rect.fromLTWH(0, 0, size.width, size.height * 0.55);
    canvas.save();
    canvas.clipRect(upper);
    for (double x = 0; x < size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, upper.height), _stroke);
    }
    for (double y = 0; y < upper.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Top bar — step dots + Skip
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showDots,
    required this.step,
    required this.onSkip,
  });

  final bool showDots;
  final int step;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CrosscueSpacing.screenH,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 60),
          if (showDots)
            _StepDots(current: step, total: 4)
          else
            const SizedBox(),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.7),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

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
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            // v3.5: active = amber accent, inactive = white @ 40% (single
            // value for both done and upcoming dots).
            color: active
                ? CrosscueColors.cellActiveLight
                : CrosscueColors.onboardingDotInactive,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock "AppBar" — title + timer + ⋮ menu, mirroring the solve screen so the
// onboarding doubles as a tour of the real UI. The ⋮ menu opens the same
// Check / Reveal / Reset items the user will see while solving.
// ---------------------------------------------------------------------------

class _MockTopBar extends StatelessWidget {
  const _MockTopBar({required this.onMenuOpened});
  final VoidCallback onMenuOpened;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        4,
        4,
        4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mini puzzle',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '00:42',
            style: TextStyle(
              fontFamily: CrosscueTypography.robotoMono,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          _MockMenuButton(onMenuOpened: onMenuOpened),
        ],
      ),
    );
  }
}

class _MockMenuButton extends StatelessWidget {
  const _MockMenuButton({required this.onMenuOpened});
  final VoidCallback onMenuOpened;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.92)),
      tooltip: 'Check / Reveal',
      onOpened: onMenuOpened,
      // Tapping items is harmless in onboarding — they're a demo of what the
      // real solve screen offers. Selection just closes the menu.
      onSelected: (_) {},
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'cl', child: Text('Check letter')),
        PopupMenuItem(value: 'cw', child: Text('Check word')),
        PopupMenuItem(value: 'cp', child: Text('Check puzzle')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'rl', child: Text('Reveal letter')),
        PopupMenuItem(value: 'rw', child: Text('Reveal word')),
        PopupMenuItem(value: 'rp', child: Text('Reveal puzzle')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'rs', child: Text('Reset puzzle')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 illustration — an oversized version of the Today screen's + FAB,
// pinned to the bottom-right of a faux "Today" card so users recognize where
// the real button lives.
// ---------------------------------------------------------------------------

class _AddPuzzleIllustration extends StatelessWidget {
  const _AddPuzzleIllustration();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // Use the light-mode tokens explicitly — the surrounding screen is navy
    // and we want this miniature to read as the (light) Today screen
    // regardless of the user's system theme. Surface is a touch grayed so
    // the FAB (the CTA) reads as the active element on top of dimmed chrome.
    const surface = Color(0xFFE8EAEE);
    const onSurface1 = CrosscueColors.onSurface2Light;
    const onSurface3 = CrosscueColors.onSurface3Light;
    const divider = CrosscueColors.dividerLight;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: surface,
          elevation: 4,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Faux AppBar
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: divider),
                        ),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onSurface1,
                        ),
                      ),
                    ),
                    // Empty-state body — mirrors home_screen.dart _EmptyState
                    const Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grid_on_outlined,
                                size: 48,
                                color: onSurface3,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No puzzles yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface1,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap + to import your own.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: onSurface3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // FAB pinned to bottom-right with an attention halo.
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse ring
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withValues(alpha: 0.18),
                          ),
                        ),
                        // Inner pulse ring
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withValues(alpha: 0.28),
                          ),
                        ),
                        // The FAB itself
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(
                              CrosscueSpacing.fabRadius,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
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

// ---------------------------------------------------------------------------
// Mock grid — empty cells fill as the user types in step 1.
// ---------------------------------------------------------------------------

class _MockGrid extends StatelessWidget {
  const _MockGrid({
    required this.focusRow,
    required this.focusCol,
    required this.focusIsAcross,
    required this.typed,
    required this.onCellTap,
  });

  final int? focusRow;
  final int? focusCol;
  final bool focusIsAcross;
  final Map<(int, int), String> typed;
  final void Function(int row, int col) onCellTap;

  @override
  Widget build(BuildContext context) {
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        // Soft paper-stack drop shadow so the grid feels lifted off the navy.
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: List.generate(5, (r) {
              return Expanded(
                child: Row(
                  children: List.generate(5, (c) {
                    final isBlack = _grid[r][c] == null;
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

                    final letter = typed[(r, c)];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onCellTap(r, c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: bg,
                            border: Border.all(color: xwTheme.gridBorder),
                          ),
                          child: isBlack || letter == null
                              ? null
                              : _InkedLetter(
                                  letter: letter,
                                  color: xwTheme.cellText,
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
      ),
    );
  }

  bool _inActiveWord(int r, int c) {
    if (focusRow == null || focusCol == null) return false;
    if (focusIsAcross) {
      return r == focusRow && _inAcrossWordBounds(focusRow!, focusCol!, c);
    } else {
      return c == focusCol && _inDownWordBounds(focusRow!, focusCol!, r);
    }
  }

  bool _inAcrossWordBounds(int r, int anchorC, int testC) {
    int start = anchorC;
    while (start > 0 && _grid[r][start - 1] != null) {
      start--;
    }
    int end = anchorC;
    while (end < 4 && _grid[r][end + 1] != null) {
      end++;
    }
    return testC >= start && testC <= end;
  }

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
// Instruction card — white sheet with drag handle, step heading, controls.
// ---------------------------------------------------------------------------

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.step,
    required this.step1Done,
    required this.step2Done,
    required this.step3Done,
    required this.onNext,
    required this.onLetter,
    required this.onStartSolving,
  });

  final int step;
  final bool step1Done;
  final bool step2Done;
  final bool step3Done;
  final VoidCallback onNext;
  final void Function(String) onLetter;
  final VoidCallback onStartSolving;

  // Fixed inner height for the card content area. Sized to comfortably fit
  // Step 1 (the tallest, with the mini keyboard). Holding this constant
  // prevents the grid above from resizing between steps.
  static const double _contentHeight = 320;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.crosscueSurface,
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
      padding: EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        12,
        CrosscueSpacing.screenH,
        16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: SizedBox(
        height: _contentHeight,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(step),
            child: switch (step) {
              0 => _Step1Card(
                  done: step1Done,
                  onLetter: onLetter,
                  onNext: onNext,
                ),
              1 => _Step2Card(done: step2Done, onNext: onNext),
              2 => _Step3Card(done: step3Done, onNext: onNext),
              _ => _Step4Card(onStartSolving: onStartSolving),
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared step heading
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
        // Monospace step label — echoes the timer typography on the solve
        // screen and the crossword/code identity of the app.
        Text(
          stepLabel,
          style: TextStyle(
            fontFamily: CrosscueTypography.robotoMono,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.crosscueOnSurface1,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            fontSize: 14,
            color: context.crosscueOnSurface2,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Primary CTA — matches FilledButton theme; consistent height/radius across
// every onboarding step so the card doesn't appear to jump.
// ---------------------------------------------------------------------------

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // v3.5 disabled-button tokens. Onboarding always reads against the navy
    // background regardless of system theme, so light-mode values apply here.
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadiusLg),
        ),
        disabledBackgroundColor: CrosscueColors.buttonDisabledBgLight,
        disabledForegroundColor: CrosscueColors.buttonDisabledTextLight,
      ),
      child: Text(label),
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
          title: 'Tap a letter to fill the cell',
          body:
              'The cursor jumps to the next empty cell. Tap a different cell to move it manually.',
        ),
        const SizedBox(height: 16),
        _MiniKeyboard(onLetter: onLetter),
        const SizedBox(height: 12),
        _PrimaryCta(
          label: 'Next',
          onPressed: done ? onNext : null,
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
          title: 'Tap the focused cell to switch direction',
          body:
              'Watch the highlight shift between across and down. This is how you pick which word to solve.',
        ),
        const SizedBox(height: 24),
        _PrimaryCta(
          label: 'Next',
          onPressed: done ? onNext : null,
        ),
      ],
    );
  }
}

class _Step3Card extends StatelessWidget {
  const _Step3Card({required this.done, required this.onNext});
  final bool done;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeading(
          stepLabel: 'STEP 3',
          title: done
              ? "That's where Check, Reveal & Reset live"
              : 'Open the ⋮ menu',
          body: done
              ? 'You can use any of these anytime while solving.'
              : 'Try opening the menu in the top right to see Check, Reveal, and Reset options.',
        ),
        const SizedBox(height: 24),
        _PrimaryCta(label: 'Next', onPressed: done ? onNext : null),
      ],
    );
  }
}

class _Step4Card extends StatelessWidget {
  const _Step4Card({required this.onStartSolving});
  final VoidCallback onStartSolving;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeading(
          stepLabel: 'STEP 4',
          title: 'Add your own puzzles',
          body:
              'Tap the + on the Today screen to import .puz files from your device, or to enable online sources like Crosshare.',
        ),
        const SizedBox(height: 24),
        _PrimaryCta(label: 'Start solving', onPressed: onStartSolving),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mini QWERTY keyboard — visual + structural match to the solve screen's
// keyboard so the onboarding feels like the real thing.
// ---------------------------------------------------------------------------

class _MiniKeyboard extends StatelessWidget {
  const _MiniKeyboard({required this.onLetter});
  final void Function(String) onLetter;

  static const _row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  static const _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  static const _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  Widget build(BuildContext context) {
    final xwTheme =
        Theme.of(context).extension<CrosswordTheme>() ?? CrosswordTheme.light();

    return Container(
      decoration: BoxDecoration(
        color: xwTheme.keyboardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _KeyRow(keys: _row1, onLetter: onLetter, xwTheme: xwTheme),
          const SizedBox(height: 4),
          _KeyRow(
            keys: _row2,
            onLetter: onLetter,
            xwTheme: xwTheme,
            sidePadding: 14,
          ),
          const SizedBox(height: 4),
          _KeyRow(
            keys: _row3,
            onLetter: onLetter,
            xwTheme: xwTheme,
            sidePadding: 28,
          ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.keys,
    required this.onLetter,
    required this.xwTheme,
    this.sidePadding = 0,
  });

  final List<String> keys;
  final void Function(String) onLetter;
  final CrosswordTheme xwTheme;
  final double sidePadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys
            .map(
              (k) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: _Key(letter: k, onLetter: onLetter, xwTheme: xwTheme),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.letter,
    required this.onLetter,
    required this.xwTheme,
  });

  final String letter;
  final void Function(String) onLetter;
  final CrosswordTheme xwTheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onLetter(letter),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: xwTheme.keyDefault,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.crosscueOnSurface1,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Letter ink-in animation — scales up and fades in when a letter first
// appears in a cell. Triggered by AnimatedSwitcher keyed on the letter.
// ---------------------------------------------------------------------------

class _InkedLetter extends StatelessWidget {
  const _InkedLetter({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, anim) {
        final scale = Tween<double>(begin: 0.55, end: 1.0).animate(anim);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: Center(
        key: ValueKey(letter),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
