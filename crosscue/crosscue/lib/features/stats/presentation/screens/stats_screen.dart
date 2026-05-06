import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/crossword_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/models/stats_data.dart';
import '../providers/stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsDataProvider);
    final theme = CrosswordTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => stats.startedCount == 0
            ? const _EmptyStats()
            : _StatsBody(stats: stats, theme: theme),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — fully flat, no cards
// ---------------------------------------------------------------------------

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats, required this.theme});

  final StatsData stats;
  final CrosswordTheme theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Streak ────────────────────────────────────────────────────────
        _StreakSection(stats: stats),
        const _SectionDivider(),

        // ── Solve times ───────────────────────────────────────────────────
        if (stats.hasSolves) ...[
          _TimesSection(stats: stats),
          const _SectionDivider(),
        ],

        // ── Totals ────────────────────────────────────────────────────────
        _TotalsSection(stats: stats),
        const _SectionDivider(),

        // ── Personal Bests ────────────────────────────────────────────────
        if (_hasPB(stats)) ...[
          _PersonalBestsSection(stats: stats),
          const _SectionDivider(),
        ],

        // ── Completion ────────────────────────────────────────────────────
        _CompletionSection(stats: stats),

        const SizedBox(height: 24),
      ],
    );
  }

  static bool _hasPB(StatsData s) =>
      s.personalBest15x15Ms != null ||
      s.personalBest21x21Ms != null ||
      s.personalBestMiniMs != null;
}

// ---------------------------------------------------------------------------
// Streak section — two columns
// ---------------------------------------------------------------------------

class _StreakSection extends StatelessWidget {
  const _StreakSection({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        20,
        CrosscueSpacing.screenH,
        CrosscueSpacing.screenH,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StreakCell(
              value: '${stats.currentStreak}',
              label: 'CURRENT',
              sub: stats.currentStreak == 1 ? 'day' : 'days',
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: CrosscueColors.dividerLight,
          ),
          Expanded(
            child: _StreakCell(
              value: '${stats.longestStreak}',
              label: 'LONGEST',
              sub: stats.longestStreak == 1 ? 'day' : 'days',
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCell extends StatelessWidget {
  const _StreakCell({
    required this.value,
    required this.label,
    required this.sub,
  });

  final String value;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: CrosscueColors.onSurface1Light,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$label\n$sub',
          style: const TextStyle(
            fontSize: CrosscueTypography.label,
            color: CrosscueColors.onSurface3Light,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Times section
// ---------------------------------------------------------------------------

class _TimesSection extends StatelessWidget {
  const _TimesSection({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        20,
        CrosscueSpacing.screenH,
        CrosscueSpacing.screenH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AVERAGE TIME',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: CrosscueColors.onSurface3Light,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatMs(stats.averageTimeMs)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: CrosscueColors.onSurface1Light,
            ),
          ),
          const SizedBox(height: 24),
          if (stats.sevenDayAverageMs != null) ...[
            const Text(
              '7-DAY AVERAGE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: CrosscueColors.onSurface3Light,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatMs(stats.sevenDayAverageMs!)}',
              style: const TextStyle(
                fontSize: 24,
                color: CrosscueColors.onSurface2Light,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatMs(int ms) {
    final total = ms ~/ 1000;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Totals section
// ---------------------------------------------------------------------------

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        20,
        CrosscueSpacing.screenH,
        CrosscueSpacing.screenH,
      ),
      child: Row(
        children: [
          Expanded(
            child: _TotalCell(
              label: 'STARTED',
              value: stats.startedCount.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: CrosscueColors.dividerLight,
          ),
          Expanded(
            child: _TotalCell(
              label: 'COMPLETED',
              value: stats.completedCount.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: CrosscueColors.onSurface1Light,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: CrosscueTypography.label,
            color: CrosscueColors.onSurface3Light,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Personal Bests section
// ---------------------------------------------------------------------------

class _PersonalBestsSection extends StatelessWidget {
  const _PersonalBestsSection({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        20,
        CrosscueSpacing.screenH,
        CrosscueSpacing.screenH,
      ),
      child: Row(
        children: [
          Expanded(
            child: _PBCell(
              label: '15×15',
              value: stats.personalBest15x15Ms != null
                  ? _formatMs(stats.personalBest15x15Ms!)
                  : '-',
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: CrosscueColors.dividerLight,
          ),
          Expanded(
            child: _PBCell(
              label: '21×21',
              value: stats.personalBest21x21Ms != null
                  ? _formatMs(stats.personalBest21x21Ms!)
                  : '-',
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: CrosscueColors.dividerLight,
          ),
          Expanded(
            child: _PBCell(
              label: 'MINI',
              value: stats.personalBestMiniMs != null
                  ? _formatMs(stats.personalBestMiniMs!)
                  : '-',
            ),
          ),
        ],
      ),
    );
  }
}

class _PBCell extends StatelessWidget {
  const _PBCell({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: CrosscueColors.onSurface1Light,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: CrosscueTypography.label,
            color: CrosscueColors.onSurface3Light,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Completion section
// ---------------------------------------------------------------------------

class _CompletionSection extends StatelessWidget {
  const _CompletionSection({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    final rate = stats.startedCount > 0
        ? (stats.completedCount / stats.startedCount * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        20,
        CrosscueSpacing.screenH,
        CrosscueSpacing.screenH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMPLETION RATE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: CrosscueColors.onSurface3Light,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: rate / 100,
                    backgroundColor: CrosscueColors.dividerLight,
                    valueColor: AlwaysStoppedAnimation(CrosscueColors.primary),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$rate%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CrosscueColors.onSurface1Light,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty stats state
// ---------------------------------------------------------------------------

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    final theme = CrosswordTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(CrosscueSpacing.screenH),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No stats yet',
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start solving puzzles to see your stats.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section divider
// ---------------------------------------------------------------------------

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: Divider(
        color: CrosscueColors.dividerLight,
      ),
    );
  }
}
