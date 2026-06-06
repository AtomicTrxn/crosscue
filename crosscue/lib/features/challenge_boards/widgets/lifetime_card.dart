// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:flutter/material.dart';
import '../models/challenge_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'atoms.dart';
import 'cb_card.dart';

/// Lifetime Stats card — deliberately quieter than the Weekly card.
/// Shows the metric triad + ranking status, or the insufficient-sample meter.
class LifetimeCard extends StatelessWidget {
  final LifetimeStats stats;
  const LifetimeCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return CbCard(
      quiet: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Eyebrow('Lifetime', suffix: '· completed weeks'),
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.onSurface3(context)),
        ]),
        const SizedBox(height: 14),
        if (!stats.hasEnoughSample)
          _Insufficient(stats: stats)
        else
          _Triad(stats: stats),
      ]),
    );
  }
}

class _Triad extends StatelessWidget {
  final LifetimeStats stats;
  const _Triad({required this.stats});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Metric(value: stats.avgClean, label: 'Avg clean', accent: true),
          Metric(
              value: '${stats.cleanSolves}',
              label: 'Clean solves',
              accent: true),
          Metric(value: stats.bestClean, label: 'Best clean', accent: true),
        ]),
      ),
      const SizedBox(height: 12),
      Divider(height: 1, color: AppColors.divider(context)),
      const SizedBox(height: 12),
      Row(children: [
        Icon(Icons.military_tech_outlined,
            size: 16, color: AppColors.onSurface2(context)),
        const SizedBox(width: 7),
        Text(stats.rankingStatus,
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurface2(context),
                fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}

class _Insufficient extends StatelessWidget {
  final LifetimeStats stats;
  const _Insufficient({required this.stats});
  @override
  Widget build(BuildContext context) {
    final done = stats.cleanSolves.clamp(0, 5);
    final togo = stats.cleanSolvesToUnlock;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    color: AppColors.onSurface1(context))),
            TextSpan(text: ' to unlock lifetime ranking. $togo to go.'),
          ])),
      const SizedBox(height: 12),
      Row(children: [
        for (int i = 0; i < 5; i++) ...[
          Expanded(
              child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: i < done
                          ? AppColors.primary(context)
                          : AppColors.divider(context),
                      borderRadius: BorderRadius.circular(3)))),
          if (i < 4) const SizedBox(width: 6),
        ],
      ]),
    ]);
  }
}
