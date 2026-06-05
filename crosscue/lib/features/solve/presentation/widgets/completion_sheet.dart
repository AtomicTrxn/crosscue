import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/share/result_share.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/core/utils/source_links.dart';
import 'package:crosscue/core/utils/time_format.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/widgets/puzzle_info_sheet.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompletionSheet extends ConsumerWidget {
  const CompletionSheet({
    super.key,
    required this.solveState,
    required this.onViewGrid,
    required this.onNextPuzzle,
    required this.onResetPuzzle,
    this.resultShare,
    this.launch,
  });

  final SolveState solveState;
  final VoidCallback onViewGrid;
  final VoidCallback onNextPuzzle;
  final VoidCallback onResetPuzzle;

  /// Injectable for tests; defaults to the platform [ResultShare].
  final ResultShare? resultShare;

  /// Injectable URL launcher forwarded to the puzzle-info sheet (tests).
  final PuzzleLinkLauncher? launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = solveState.status;
    final isRevealed = status == PuzzleStatus.revealed;

    final solveLabel = switch (status) {
      PuzzleStatus.solved => 'Clean solve',
      PuzzleStatus.solvedWithHelp => 'Solved with checks',
      PuzzleStatus.solvedWithReveal => 'Solved with hints',
      PuzzleStatus.revealed => 'Puzzle revealed',
      _ => 'Completed',
    };

    final m = solveState.elapsedSeconds ~/ 60;
    final s = solveState.elapsedSeconds % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final statsAsync = ref.watch(statsDataProvider);
    final streak = statsAsync.asData?.value.currentStreak ?? 0;
    final previousBest = solveState.previousPersonalBestMs;
    final elapsedMs = solveState.elapsedSeconds * 1000;
    final isNewPersonalBest = status == PuzzleStatus.solved &&
        previousBest != null &&
        elapsedMs < previousBest;

    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.35,
      maxChildSize: 0.75,
      expand: false,
      builder: (ctx, scrollController) {
        final onSurface1 = ctx.crosscueOnSurface1;
        final onSurface2 = ctx.crosscueOnSurface2;
        final divider = ctx.crosscueDivider;
        final correct = ctx.crosscueCorrect;
        return Container(
          decoration: BoxDecoration(
            color: ctx.crosscueSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(CrosscueSpacing.sheetRadius),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                CrosscueSpacing.screenH,
                12,
                CrosscueSpacing.screenH,
                24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: CrosscueSpacing.dragHandleW,
                    height: CrosscueSpacing.dragHandleH,
                    decoration: BoxDecoration(
                      color: divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/ic_launcher.png',
                      width: 44,
                      height: 44,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    solveLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onSurface1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontFamily: CrosscueTypography.robotoMono,
                      fontSize: CrosscueTypography.timerLarge,
                      fontWeight: FontWeight.w700,
                      color: onSurface1,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: divider),
                  const SizedBox(height: 12),
                  if (isNewPersonalBest) ...[
                    Text(
                      '↑ New personal best — prev. ${formatMs(previousBest)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: correct,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: divider),
                    const SizedBox(height: 12),
                  ],
                  if (streak > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          '$streak-day streak',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: onSurface1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: divider),
                  ],
                  const SizedBox(height: 16),
                  if (!isRevealed) ...[
                    SizedBox(
                      width: double.infinity,
                      // Builder so the tap handler can read THIS button's
                      // render box for the iPad share-sheet popover anchor.
                      child: Builder(
                        builder: (buttonCtx) => OutlinedButton(
                          onPressed: () => _shareResult(
                            buttonCtx,
                            solveState,
                            timeStr,
                            solveLabel,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: onSurface2,
                            side: BorderSide(color: divider, width: 1),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            minimumSize: const Size.fromHeight(46),
                          ),
                          child: const Text('Share result'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (crosshareUrlFor(solveState.puzzle.metadata) != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showPuzzleInfoSheet(
                          ctx,
                          solveState.puzzle.metadata,
                          launch: launch,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: onSurface2,
                          side: BorderSide(color: divider, width: 1),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Puzzle info'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onViewGrid,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onSurface2,
                        side: BorderSide(color: divider, width: 1),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('View completed puzzle'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onNextPuzzle,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(ctx).colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Next puzzle'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _confirmReset(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: ctx.crosscueActionDestructive,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: const Text('Reset puzzle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareResult(
    BuildContext context,
    SolveState solveState,
    String timeStr,
    String solveLabel,
  ) async {
    // iPad presents the share sheet as a popover anchored to a rect — pass the
    // button's frame so it doesn't fail to present. (Ignored on iPhone.)
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      await (resultShare ?? ResultShare()).share(
        text: '${solveState.puzzle.metadata.title}\n'
            '$timeStr - $solveLabel\n'
            'Solved in Crosscue',
        subject: 'Crosscue result',
        origin: origin,
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the share sheet.")),
        );
      }
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
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
                backgroundColor: ctx.crosscueActionDestructive,
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
      onResetPuzzle();
    }
  }
}
