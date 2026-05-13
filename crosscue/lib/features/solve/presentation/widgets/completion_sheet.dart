import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/utils/time_format.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class CompletionSheet extends ConsumerWidget {
  const CompletionSheet({
    super.key,
    required this.solveState,
    required this.onViewGrid,
    required this.onNextPuzzle,
  });

  final SolveState solveState;
  final VoidCallback onViewGrid;
  final VoidCallback onNextPuzzle;

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
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
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
                    color: CrosscueColors.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  solveLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CrosscueColors.onSurface1Light,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: CrosscueTypography.robotoMono,
                    fontSize: CrosscueTypography.timerLarge,
                    fontWeight: FontWeight.w700,
                    color: CrosscueColors.onSurface1Light,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: CrosscueColors.dividerLight),
                const SizedBox(height: 12),
                if (isNewPersonalBest) ...[
                  Text(
                    '↑ New personal best — prev. ${formatMs(previousBest)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CrosscueColors.correctLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: CrosscueColors.dividerLight),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CrosscueColors.onSurface1Light,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: CrosscueColors.dividerLight),
                ],
                const SizedBox(height: 16),
                if (!isRevealed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: '${solveState.puzzle.metadata.title}\n'
                                '$timeStr - $solveLabel\n'
                                'Solved in Crosscue',
                            subject: 'Crosscue result',
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CrosscueColors.onSurface2Light,
                        side: const BorderSide(
                          color: CrosscueColors.dividerLight,
                          width: 1,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Share result'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onViewGrid,
                    style: TextButton.styleFrom(
                      foregroundColor: CrosscueColors.onSurface3Light,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    child: const Text('View filled grid'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onNextPuzzle,
                    style: FilledButton.styleFrom(
                      backgroundColor: CrosscueColors.primary,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
