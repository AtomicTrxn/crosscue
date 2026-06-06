// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:flutter/material.dart';
import '../models/challenge_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../util/utc_week.dart';
import 'atoms.dart';
import 'board_row.dart';
import 'cb_card.dart';

/// Weekly Challenge card — the primary surface. Header (eyebrow + reset
/// countdown) over up to 5 compact [BoardRow]s.
class WeeklyCard extends StatelessWidget {
  final List<Board> boards;
  final void Function(Board)? onOpenBoard;
  const WeeklyCard({super.key, required this.boards, this.onOpenBoard});

  @override
  Widget build(BuildContext context) {
    return CbCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Eyebrow('This week', suffix: '· UTC'),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.schedule_rounded,
                size: 13, color: AppColors.onSurface3(context)),
            const SizedBox(width: 5),
            Text(UtcWeek.resetCountdownLabel(),
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.onSurface3(context),
                    fontWeight: FontWeight.w500)),
          ]),
        ]),
        const SizedBox(height: 8),
        for (int i = 0; i < boards.length; i++)
          BoardRow(
              board: boards[i],
              isLast: i == boards.length - 1,
              onTap: () => onOpenBoard?.call(boards[i])),
      ]),
    );
  }
}

/// 0-board entry state — leads with the two ways in.
class WeeklyEmpty extends StatelessWidget {
  final VoidCallback? onCreate;
  final VoidCallback? onJoin;
  const WeeklyEmpty({super.key, this.onCreate, this.onJoin});

  @override
  Widget build(BuildContext context) {
    return CbCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('This week', suffix: '· UTC'),
        const SizedBox(height: 18),
        Center(
            child: Column(children: [
          Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: AppColors.primaryContainer(context),
                  shape: BoxShape.circle),
              child: Icon(Icons.emoji_events_outlined,
                  size: 26, color: AppColors.primary(context))),
          const SizedBox(height: 14),
          Text('Start a challenge with friends',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 16, color: AppColors.onSurface1(context))),
          const SizedBox(height: 6),
          Text(
              'Create a private board or join one with an invite link. Compete on Daily Mini times each week.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.onSurface2(context))),
          const SizedBox(height: 18),
          FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create a board')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Join with a link')),
        ])),
      ]),
    );
  }
}

/// Loading skeleton — three placeholder rows, never a spinner.
class WeeklyLoading extends StatelessWidget {
  const WeeklyLoading({super.key});
  @override
  Widget build(BuildContext context) {
    return CbCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Skeleton(width: 84, height: 11),
          Skeleton(width: 96, height: 11),
        ]),
        const SizedBox(height: 14),
        for (int i = 0; i < 3; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                border: i < 2
                    ? Border(
                        bottom: BorderSide(color: AppColors.divider(context)))
                    : null),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Skeleton(width: i == 0 ? 150 : 120, height: 13),
                    const SizedBox(height: 8),
                    const Skeleton(width: 180, height: 10),
                  ])),
              const Skeleton(width: 42, height: 22, radius: 999),
            ]),
          ),
      ]),
    );
  }
}
