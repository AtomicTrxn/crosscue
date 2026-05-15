import 'package:crosscue/core/theme/app_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/check_result.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SolveAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SolveAppBar({
    super.key,
    required this.puzzleId,
    required this.title,
    required this.solveState,
    required this.isComplete,
  });

  final String puzzleId;
  final String title;
  final SolveState solveState;
  final bool isComplete;

  @override
  Size get preferredSize =>
      const Size.fromHeight(CrosscueSpacing.appBarHeightSolve);

  String? _sourceLabel(String sourceId) {
    if (sourceId == 'local_import') return null;
    return switch (sourceId) {
      'crosshare_daily_mini' => 'via Crosshare',
      _ => 'via $sourceId',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceLabel = _sourceLabel(solveState.puzzle.metadata.sourceId);

    return AppBar(
      toolbarHeight: CrosscueSpacing.appBarHeightSolve,
      leading: BackButton(onPressed: () => context.pop()),
      centerTitle: true,
      title: sourceLabel != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sourceLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.crosscueOnSurface3,
                        fontSize: 11,
                      ),
                ),
              ],
            )
          : Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        if (isComplete)
          Center(
            child: _TimerDisplay(
              seconds: solveState.elapsedSeconds,
              isPaused: false,
            ),
          )
        else
          GestureDetector(
            onTap: () {
              final notifier = ref.read(solveProvider(puzzleId).notifier);
              if (solveState.isPaused) {
                notifier.resume();
              } else {
                notifier.pause();
              }
            },
            child: Center(
              child: _TimerDisplay(
                seconds: solveState.elapsedSeconds,
                isPaused: solveState.isPaused,
              ),
            ),
          ),
        if (isComplete)
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset puzzle',
            onPressed: () => _confirmResetFromAppBar(context, ref, puzzleId),
          )
        else
          _CheckRevealMenu(puzzleId: puzzleId),
        const SizedBox(width: 4),
      ],
    );
  }
}

enum _CheckRevealOption {
  checkLetter,
  checkWord,
  checkPuzzle,
  divider,
  revealLetter,
  revealWord,
  revealPuzzle,
  divider2,
  resetPuzzle,
}

class _CheckRevealMenu extends ConsumerWidget {
  const _CheckRevealMenu({required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_CheckRevealOption>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Check / Reveal',
      onSelected: (option) => _onSelected(context, ref, option),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _CheckRevealOption.checkLetter,
          child: Text('Check letter'),
        ),
        PopupMenuItem(
          value: _CheckRevealOption.checkWord,
          child: Text('Check word'),
        ),
        PopupMenuItem(
          value: _CheckRevealOption.checkPuzzle,
          child: Text('Check puzzle'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _CheckRevealOption.revealLetter,
          child: Text('Reveal letter'),
        ),
        PopupMenuItem(
          value: _CheckRevealOption.revealWord,
          child: Text('Reveal word'),
        ),
        PopupMenuItem(
          value: _CheckRevealOption.revealPuzzle,
          child: Text('Reveal puzzle'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _CheckRevealOption.resetPuzzle,
          child: Text('Reset puzzle'),
        ),
      ],
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    _CheckRevealOption option,
  ) async {
    final notifier = ref.read(solveProvider(puzzleId).notifier);

    switch (option) {
      case _CheckRevealOption.checkLetter:
        _vibrateIfIncorrect(ref, notifier.checkCell());
      case _CheckRevealOption.checkWord:
        _vibrateIfIncorrect(ref, notifier.checkWord());
      case _CheckRevealOption.checkPuzzle:
        _vibrateIfIncorrect(ref, notifier.checkGrid());
      case _CheckRevealOption.revealLetter:
        notifier.revealCell();
      case _CheckRevealOption.revealWord:
        notifier.revealWord();
      case _CheckRevealOption.revealPuzzle:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reveal puzzle?'),
            content: const Text(
              'This will fill the whole puzzle. The solve will not count toward your streak.',
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: CrosscueColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Reveal'),
              ),
            ],
          ),
        );
        if (confirmed == true) notifier.revealPuzzle();
      case _CheckRevealOption.resetPuzzle:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final primary = Theme.of(ctx).colorScheme.primary;
            return AlertDialog(
              title: const Text('Reset puzzle?'),
              content: const Text(
                'All your progress, checks, and reveals will be cleared. '
                'The timer will restart from zero.',
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ctx.crosscueError,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
        if (confirmed == true) notifier.resetPuzzle();
      case _CheckRevealOption.divider:
      case _CheckRevealOption.divider2:
        break;
    }
  }

  void _vibrateIfIncorrect(WidgetRef ref, CheckResult result) {
    final hapticsOn = ref.read(hapticsEnabledProvider).when(
          data: (value) => value,
          loading: () => true,
          error: (_, __) => true,
        );
    if (result.shouldVibrate && hapticsOn) {
      HapticFeedback.vibrate();
    }
  }
}

Future<void> _confirmResetFromAppBar(
  BuildContext context,
  WidgetRef ref,
  String puzzleId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final primary = Theme.of(ctx).colorScheme.primary;
      return AlertDialog(
        title: const Text('Reset puzzle?'),
        content: const Text(
          'Your progress will be cleared and the timer will restart from '
          'zero. Your original completion is preserved in your stats and '
          'streak.',
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.crosscueError,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      );
    },
  );
  if (confirmed == true) {
    ref.read(solveProvider(puzzleId).notifier).resetPuzzle();
  }
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.seconds, required this.isPaused});

  final int seconds;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final text =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPaused) ...[
          const Icon(Icons.pause, size: 14),
          const SizedBox(width: 3),
        ],
        Text(text, style: context.timerStyle),
        const SizedBox(width: 8),
      ],
    );
  }
}
