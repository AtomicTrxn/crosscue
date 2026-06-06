// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:flutter/material.dart';
import '../models/challenge_models.dart';
import '../sample/sample_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../util/utc_week.dart';
import '../widgets/leaderboard_row.dart';
import '../widgets/segmented_control.dart';

/// Board detail — weekly + lifetime leaderboards behind a segmented control.
class BoardDetailScreen extends StatefulWidget {
  final String boardName;
  final int playerCount;
  final List<LeaderboardEntry> weekly;
  final List<LeaderboardEntry> lifetime;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onShare;
  final VoidCallback? onRegenerate;
  final VoidCallback? onLeave;

  const BoardDetailScreen({
    super.key,
    this.boardName = 'Friday Night Crew',
    this.playerCount = 8,
    this.weekly = SampleData.weeklyLeaderboard,
    this.lifetime = SampleData.weeklyLeaderboard,
    this.onRefresh,
    this.onShare,
    this.onRegenerate,
    this.onLeave,
  });

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  int _index = 0; // 0 = weekly, 1 = lifetime

  @override
  Widget build(BuildContext context) {
    final mode =
        _index == 0 ? LeaderboardMode.weekly : LeaderboardMode.lifetime;
    final rows = _index == 0 ? widget.weekly : widget.lifetime;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Text(widget.boardName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.onSurface1(context))),
        actions: [
          IconButton(
              onPressed: widget.onShare,
              icon: const Icon(Icons.ios_share_rounded, size: 20)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              if (v == 'regen') widget.onRegenerate?.call();
              if (v == 'leave') widget.onLeave?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'regen', child: Text('Regenerate invite link')),
              PopupMenuItem(
                  value: 'leave',
                  child: Text('Leave board',
                      style: TextStyle(
                          color: AppColors.actionDestructive(context)))),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            Icon(Icons.group_outlined,
                size: 14, color: AppColors.onSurface2(context)),
            const SizedBox(width: 8),
            Text('${widget.playerCount} players · invite-only',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurface2(context),
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CbSegmented(
                options: const ['This week', 'Lifetime'],
                selectedIndex: _index,
                onChanged: (i) => setState(() => _index = i)),
            const SizedBox(height: 10),
            Text(
                mode == LeaderboardMode.lifetime
                    ? '${UtcWeek.lifetimeBasis} · ${widget.lifetime.isEmpty ? 0 : (widget.lifetime.first.weeksCounted ?? 16)} weeks counted'
                    : '${UtcWeek.detailBoundaryLabel} · updated 2h ago',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.onSurface3(context))),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              itemCount: rows.length,
              itemBuilder: (_, i) => LeaderboardRow(entry: rows[i], mode: mode),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: AppColors.divider(context)))),
          child: SafeArea(
              top: false,
              child: OutlinedButton.icon(
                onPressed: widget.onShare,
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('Share invite link'),
              )),
        ),
      ]),
    );
  }
}
