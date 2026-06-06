// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:flutter/material.dart';
import '../models/challenge_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'atoms.dart';

/// One compact board row inside the Weekly card. Tapping opens board detail.
class BoardRow extends StatelessWidget {
  final Board board;
  final bool isLast;
  final VoidCallback? onTap;
  const BoardRow(
      {super.key, required this.board, this.isLast = false, this.onTap});

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
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(board.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            color: AppColors.onSurface1(context))),
                    const SizedBox(height: 4),
                    Text(
                        '${board.rankingMode.metricLabel} ${s.metricFor(board.rankingMode)} · ${s.cleanSolves} clean · ${board.playerCount} players',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.onSurface3(context))),
                  ]),
            ),
            const SizedBox(width: 10),
            RankChip(rank: s.rank, outOf: s.outOf, first: s.isFirst),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.onSurface3(context)),
          ]),
        ),
      ),
    );
  }
}
