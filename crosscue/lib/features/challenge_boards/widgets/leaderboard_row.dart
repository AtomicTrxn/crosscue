import 'package:crosscue/features/challenge_boards/avatar/player_avatar.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// A single leaderboard row in board detail. The signed-in player's row is
/// highlighted and carries a "YOU" text badge (never color-only).
class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final LeaderboardMode mode;
  final ChallengeRankingMode rankingMode;
  const LeaderboardRow({
    super.key,
    required this.entry,
    required this.mode,
    this.rankingMode = ChallengeRankingMode.averageTime,
  });

  @override
  Widget build(BuildContext context) {
    final you = entry.player.isMe;
    final top = entry.rank == 1;
    final rankColor = top
        ? const Color(0xFFFF9800)
        : you
            ? AppColors.primary(context)
            : AppColors.onSurface2(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: you ? AppColors.primaryContainer(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          PlayerAvatarView(
            avatar: entry.player.avatar,
            name: entry.player.displayName,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.player.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 14.5,
                          fontWeight: you ? FontWeight.w700 : FontWeight.w600,
                          height: 1.1,
                          color: AppColors.onSurface1(context),
                        ),
                      ),
                    ),
                    if (you) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          border: Border.all(color: AppColors.primary(context)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.primary(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mode == LeaderboardMode.lifetime
                      ? '${entry.avgClean} avg · ${entry.weeksCounted ?? 0} weeks'
                      : '${rankingMode.label} · ${entry.cleanSolves} clean',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.onSurface3(context)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mode == LeaderboardMode.lifetime
                    ? '${entry.cleanSolves}'
                    : entry.metricFor(rankingMode),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.onSurface1(context),
                ),
              ),
              Text(
                mode == LeaderboardMode.lifetime
                    ? 'CLEAN'
                    : rankingMode.metricLabel.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.onSurface3(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
