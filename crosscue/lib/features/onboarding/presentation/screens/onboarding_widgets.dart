part of 'onboarding_screen.dart';

// ===========================================================================
// Step 0 — Welcome
// ===========================================================================

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({
    super.key,
    required this.onGetStarted,
    required this.onHowToPlay,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onHowToPlay;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.crosscueOnbHeroGradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CrosscueSpacing.screenH,
            24,
            CrosscueSpacing.screenH,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              const _BrandMark(),
              const SizedBox(height: 24),
              const Text(
                'Crosscue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your daily crossword,\nbeautifully simple.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const Spacer(flex: 4),
              const _PageDots(current: 0, onDark: true),
              const SizedBox(height: 20),
              _PrimaryCta(
                label: 'Get started',
                onDark: true,
                onPressed: onGetStarted,
              ),
              const SizedBox(height: 4),
              _HowToPlayLink(onTap: onHowToPlay, onDark: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  // A tiny 3×3 mini-grid glyph echoing the crossword identity.
  @override
  Widget build(BuildContext context) {
    const filled = Color(0xFFFFFFFF);
    final empty = Colors.white.withValues(alpha: 0.18);
    const pattern = [true, true, false, false, true, true, true, false, true];
    return Center(
      child: SizedBox(
        width: 84,
        height: 84,
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final on in pattern)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: on ? filled : empty,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Step 1 — Source choice
// ===========================================================================

class _SourceChoiceView extends StatelessWidget {
  const _SourceChoiceView({
    super.key,
    required this.wantCrosshare,
    required this.wantImport,
    required this.onToggleCrosshare,
    required this.onToggleImport,
    required this.canContinue,
    required this.onContinue,
    required this.onLater,
    required this.onHowToPlay,
  });

  final bool wantCrosshare;
  final bool wantImport;
  final VoidCallback onToggleCrosshare;
  final VoidCallback onToggleImport;
  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback onLater;
  final VoidCallback onHowToPlay;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CrosscueSpacing.screenH,
          16,
          CrosscueSpacing.screenH,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PageDots(current: 1, onDark: false),
            const SizedBox(height: 28),
            Text(
              'Where should puzzles\ncome from?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: context.crosscueOnSurface1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick one or both. You can change this anytime in Settings.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: context.crosscueOnSurface2,
              ),
            ),
            const SizedBox(height: 24),
            _SourceCard(
              icon: Icons.download_for_offline_outlined,
              title: 'Crosshare Daily Mini',
              subtitle: 'A fresh mini every day, synced automatically. Free.',
              selected: wantCrosshare,
              onTap: onToggleCrosshare,
            ),
            const SizedBox(height: 12),
            _SourceCard(
              icon: Icons.folder_open_outlined,
              title: 'Import your own',
              subtitle:
                  'Bring .puz and .ipuz puzzles from NYT and more. They stay on your device.',
              selected: wantImport,
              onTap: onToggleImport,
            ),
            const Spacer(),
            _PrimaryCta(
              label: 'Continue',
              onPressed: canContinue ? onContinue : null,
            ),
            TextButton(
              onPressed: onLater,
              child: Text(
                "I'll set this up later",
                style: TextStyle(color: context.crosscueOnSurface2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.crosscuePrimary;
    final borderColor = selected ? primary : context.crosscueDivider;
    final bg =
        selected ? context.crosscuePrimaryContainer : context.crosscueSurface;

    return Semantics(
      button: true,
      checked: selected,
      label: title,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.crosscueOnSurface1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: context.crosscueOnSurface2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? primary : context.crosscueOnSurface3,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Step 2 — iCloud opt-in (skippable)
// ===========================================================================

class _ICloudView extends StatelessWidget {
  const _ICloudView({
    super.key,
    required this.onEnable,
    required this.onSkip,
  });

  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CrosscueSpacing.screenH,
          16,
          CrosscueSpacing.screenH,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PageDots(current: 2, onDark: false),
            const SizedBox(height: 28),
            Icon(
              Icons.cloud_outlined,
              size: 56,
              color: context.crosscuePrimary,
            ),
            const SizedBox(height: 20),
            Text(
              'Sync across\nyour devices',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: context.crosscueOnSurface1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep your puzzles, progress, and stats in sync through your '
              'private iCloud Drive. Nothing is sent to Crosscue — your data '
              'stays in your own iCloud account. You can change this anytime '
              'in Settings.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: context.crosscueOnSurface2,
              ),
            ),
            const Spacer(),
            _PrimaryCta(label: 'Turn on iCloud Sync', onPressed: onEnable),
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Not now',
                style: TextStyle(color: context.crosscueOnSurface2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Step 3 — Fetch / result
// ===========================================================================

class _FetchView extends StatelessWidget {
  const _FetchView({
    super.key,
    required this.wantCrosshare,
    required this.wantImport,
    required this.state,
    required this.onStartSolving,
    required this.onGoToday,
    required this.onRetry,
    required this.onChooseFile,
    required this.onLater,
  });

  final bool wantCrosshare;
  final bool wantImport;
  final CrosshareState state;
  final void Function(String puzzleId) onStartSolving;
  final VoidCallback onGoToday;
  final VoidCallback onRetry;
  final VoidCallback onChooseFile;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CrosscueSpacing.screenH,
          16,
          CrosscueSpacing.screenH,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PageDots(current: 3, onDark: false),
            Expanded(child: Center(child: _body(context))),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    // Import-only path: no download, just point the user at the file picker.
    if (!wantCrosshare) {
      return _ResultPanel(
        icon: Icons.folder_open_outlined,
        iconColor: context.crosscuePrimary,
        title: 'Bring your own puzzles',
        message:
            'Choose a .puz or .ipuz file to add your first puzzle. They stay on your device.',
        primaryLabel: 'Choose a file',
        onPrimary: onChooseFile,
        secondaryLabel: "I'll do it later",
        onSecondary: onLater,
      );
    }

    return switch (state) {
      CrosshareSuccess(:final puzzleId, :final title) => _ResultPanel(
          icon: Icons.check_circle_outline,
          iconColor: context.crosscueCorrect,
          title: "You're all set",
          message: 'Today\'s mini is ready: "$title".',
          primaryLabel: 'Start solving',
          onPrimary: () => onStartSolving(puzzleId),
          secondaryLabel: wantImport ? 'Import your own file' : null,
          onSecondary: wantImport ? onChooseFile : null,
        ),
      CrosshareDuplicate() => _ResultPanel(
          icon: Icons.check_circle_outline,
          iconColor: context.crosscueCorrect,
          title: "Today's mini is already here",
          message: 'It\'s waiting for you on the Today screen.',
          primaryLabel: 'Open Today',
          onPrimary: onGoToday,
          secondaryLabel: wantImport ? 'Import your own file' : null,
          onSecondary: wantImport ? onChooseFile : null,
        ),
      CrosshareFailure(:final message) => _ResultPanel(
          icon: Icons.cloud_off_outlined,
          iconColor: context.crosscueError,
          title: 'Almost there',
          message:
              "$message We'll grab today's mini automatically the moment it's ready.",
          primaryLabel: 'Go to Today',
          onPrimary: onGoToday,
          secondaryLabel: 'Try again',
          onSecondary: onRetry,
        ),
      // Idle (before download() lands) or downloading → loading.
      _ => const _LoadingPanel(),
    };
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(context.crosscuePrimary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Getting today's mini…",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.crosscueOnSurface1,
          ),
        ),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 56, color: iconColor),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.crosscueOnSurface1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: context.crosscueOnSurface2,
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryCta(label: primaryLabel, onPressed: onPrimary),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: onSecondary,
            child: Text(secondaryLabel!),
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// Shared widgets
// ===========================================================================

/// Primary CTA — full-width FilledButton with consistent height/radius.
/// On the navy welcome hero ([onDark]) it inverts to a white fill so it reads
/// against the gradient; elsewhere it uses the themed primary.
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onPressed,
    this.onDark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrosscueSpacing.buttonRadiusLg),
      ),
      backgroundColor: onDark ? Colors.white : null,
      foregroundColor: onDark ? CrosscueColors.deepNavy : null,
    );
    return FilledButton(
      onPressed: onPressed,
      style: style,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// "New to crosswords? How to play →" — the persistent footer link that points
/// at the tutorial in Settings → Help.
class _HowToPlayLink extends StatelessWidget {
  const _HowToPlayLink({required this.onTap, this.onDark = false});

  final VoidCallback onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color =
        onDark ? Colors.white.withValues(alpha: 0.9) : context.crosscuePrimary;
    return TextButton(
      onPressed: onTap,
      child: Text(
        'New to crosswords?  How to play',
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// 4-step progress indicator. [onDark] tunes the palette for the navy hero.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.onDark});

  static const _stepCount = 4;

  final int current;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final active =
        onDark ? CrosscueColors.cellActiveLight : context.crosscuePrimary;
    final inactive = onDark
        ? CrosscueColors.onboardingDotInactive
        : context.crosscueOnSurface3.withValues(alpha: 0.4);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_stepCount, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
