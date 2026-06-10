import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_text_styles.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/atoms.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/board_sheets.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/cb_card.dart';
import 'package:flutter/material.dart';

/// Lifetime Stats card — deliberately quieter than the Weekly card.
/// Shows the metric triad + ranking status, or the insufficient-sample meter.
class LifetimeCard extends StatelessWidget {
  final LifetimeStats stats;
  const LifetimeCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return CbCard(
      quiet: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Eyebrow('Lifetime', suffix: '· completed weeks'),
              IconButton(
                onPressed: () => _showLifetimeInfo(context),
                tooltip: 'About lifetime stats',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.onSurface3(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!stats.hasEnoughSample)
            _Insufficient(stats: stats)
          else
            _Triad(stats: stats),
        ],
      ),
    );
  }

  Future<void> _showLifetimeInfo(BuildContext context) {
    return showCbSheet<void>(
      context,
      title: 'Lifetime stats',
      builder: (ctx) {
        final body = AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurface2(ctx),
          height: 1.4,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lifetime stats cover every clean Daily Mini solve you have '
              'submitted — solves with no checks, hints, or reveals.',
              style: body,
            ),
            const SizedBox(height: 12),
            Text(
              'Solve 5 clean puzzles to unlock your lifetime ranking. '
              'Weeks are counted as completed Monday-to-Sunday UTC weeks '
              'containing at least one clean solve.',
              style: body,
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _Triad extends StatelessWidget {
  final LifetimeStats stats;
  const _Triad({required this.stats});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Metric(value: stats.avgClean, label: 'Avg clean', accent: true),
              Metric(
                value: '${stats.cleanSolves}',
                label: 'Clean solves',
                accent: true,
              ),
              Metric(value: stats.bestClean, label: 'Best clean', accent: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: AppColors.divider(context)),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.military_tech_outlined,
              size: 16,
              color: AppColors.onSurface2(context),
            ),
            const SizedBox(width: 7),
            Text(
              stats.rankingStatus,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurface2(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Insufficient extends StatelessWidget {
  final LifetimeStats stats;
  const _Insufficient({required this.stats});
  @override
  Widget build(BuildContext context) {
    final done = stats.cleanSolves.clamp(0, 5);
    final togo = stats.cleanSolvesToUnlock;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.onSurface2(context)),
            children: [
              const TextSpan(text: 'Solve '),
              TextSpan(
                text: '5 clean puzzles',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface1(context),
                ),
              ),
              TextSpan(text: ' to unlock lifetime ranking. $togo to go.'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < 5; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < done
                        ? AppColors.primary(context)
                        : AppColors.divider(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < 4) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}
