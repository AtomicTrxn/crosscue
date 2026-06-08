import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_text_styles.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/atoms.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/avatar/player_avatar.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/lifetime_card.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/weekly_card.dart';
import 'package:crosscue/features/challenge_boards/sample/sample_data.dart';
import 'package:flutter/material.dart';

/// The Challenge primary tab. Wire [boards] / [lifetime] to your providers;
/// defaults render the sample data so the screen runs standalone.
class ChallengeTabScreen extends StatelessWidget {
  final Loadable<List<Board>> boards;
  final LifetimeStats lifetime;
  final Player me;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onEditName;
  final VoidCallback? onCreateOrJoin;
  final void Function(Board)? onOpenBoard;

  const ChallengeTabScreen({
    super.key,
    this.boards = const Loadable.data(SampleData.boards),
    this.lifetime = SampleData.lifetime,
    this.me = SampleData.me,
    this.onRefresh,
    this.onEditName,
    this.onCreateOrJoin,
    this.onOpenBoard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              me: me,
              onEditName: onEditName,
              onCreateOrJoin: onCreateOrJoin,
            ),
            Divider(height: 1, color: AppColors.divider(context)),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh ?? () async {},
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  children: _body(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    switch (boards.status) {
      case LoadStatus.loading:
        return const [WeeklyLoading()];
      case LoadStatus.error:
        return [_ErrorCard(onRetry: onRefresh)];
      case LoadStatus.offline:
      case LoadStatus.data:
        final list = boards.data ?? const <Board>[];
        return [
          if (boards.status == LoadStatus.offline)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StatusBanner(
                tone: BannerTone.offline,
                icon: Icons.cloud_off_rounded,
                text:
                    'Offline — showing standings from ${boards.lastUpdatedLabel ?? 'earlier'}',
              ),
            ),
          if (list.isEmpty)
            WeeklyEmpty(onCreate: onCreateOrJoin, onJoin: onCreateOrJoin)
          else
            WeeklyCard(boards: list, onOpenBoard: onOpenBoard),
          const SizedBox(height: 14),
          LifetimeCard(stats: lifetime),
          const SizedBox(height: 8),
          FreshnessLine(
            boards.status == LoadStatus.offline
                ? 'Last updated ${boards.lastUpdatedLabel ?? 'earlier'}'
                : 'Updated just now · pull to refresh',
          ),
        ];
    }
  }
}

class _Header extends StatelessWidget {
  final Player me;
  final VoidCallback? onEditName;
  final VoidCallback? onCreateOrJoin;
  const _Header({required this.me, this.onEditName, this.onCreateOrJoin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Challenge',
            style: AppTextStyles.displayMedium
                .copyWith(fontSize: 26, color: AppColors.onSurface1(context)),
          ),
          Row(
            children: [
              // profile / display-name chip → edit name
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onEditName,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider(context)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayerAvatarView(
                        avatar: me.avatar,
                        name: me.displayName,
                        size: 24,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        me.displayName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface1(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // create / join
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onCreateOrJoin,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final Future<void> Function()? onRetry;
  const _ErrorCard({this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.incorrect(context).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 24,
              color: AppColors.incorrect(context),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Couldn’t load your boards',
            style: AppTextStyles.titleMedium
                .copyWith(fontSize: 16, color: AppColors.onSurface1(context)),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again. Your standings are safe.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.onSurface2(context)),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => onRetry?.call(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
