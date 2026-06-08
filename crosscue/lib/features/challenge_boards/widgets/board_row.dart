import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/theme/app_text_styles.dart';
import 'package:crosscue/features/challenge_boards/widgets/atoms.dart';
import 'package:flutter/material.dart';

/// One compact board row inside the Weekly card. Tapping opens board detail.
class BoardRow extends StatelessWidget {
  final Board board;
  final bool isLast;
  final VoidCallback? onTap;
  const BoardRow({
    super.key,
    required this.board,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = board.myWeekly;
    return InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '${board.name}, you are ranked ${s.rank} of ${s.outOf}, '
            '${board.rankingMode.metricLabel.toLowerCase()} ${s.metricFor(board.rankingMode)}. Opens board.',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: AppColors.divider(context))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      board.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: AppColors.onSurface1(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${board.rankingMode.metricLabel} ${s.metricFor(board.rankingMode)} · ${s.cleanSolves} clean · ${board.playerCount} players',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.onSurface3(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RankChip(rank: s.rank, outOf: s.outOf, first: s.isFirst),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.onSurface3(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
