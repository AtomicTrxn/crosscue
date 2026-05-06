import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../domain/models/stats_data.dart';
import '../providers/stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => stats.startedCount == 0
            ? const _EmptyStats()
            : _StatsBody(stats: stats),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — fully flat, no cards
// ---------------------------------------------------------------------------

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final StatsData stats;

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CrosscueColors.onSurface3Light,
            letterSpacing: 1.0,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: CrosscueColors.onSurface1Light,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
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
// Solve times section — three columns, Roboto Mono values
// ---------------------------------------------------------------------------

class _TimesSection extends StatelessWidget {
  const _TimesSection({required this.stats});
  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CrosscueSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('TIMES'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimeCell(
                  value: stats.averageElapsedMs != null
                      ? _formatMs(stats.averageElapsedMs!)
                      : '–',
                  label: 'AVG ALL',
                  sub: 'overall',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _TimeCell(
                  value: stats.sevenDayAverageMs != null
                      ? _formatMs(stats.sevenDayAverageMs!)
                      : '–',
                  label: '7-DAY AVG',
                  sub: 'last 7 days',
                ),
              ),
              _VerticalDivider(),
              const Expanded(child: SizedBox()), // placeholder third column
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({
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
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: CrosscueTypography.robotoMono,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: CrosscueColors.onSurface1Light,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CrosscueColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 10,
            color: CrosscueColors.onSurface3Light,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Totals section — three columns
// ---------------------------------------------------------------------------

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.stats});
  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalSolved + stats.revealedCount;
    return Padding(
      padding: const EdgeInsets.all(CrosscueSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('SOLVES'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TotalCell(
                  value: '$total',
                  label: 'TOTAL',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _TotalCell(
                  value: '${stats.cleanSolves}',
                  label: 'CLEAN',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _TotalCell(
                  value: '${stats.hintedCheckedSolves + stats.revealedCount}',
                  label: 'WITH HELP',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: CrosscueColors.onSurface1Light,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: CrosscueColors.onSurface3Light,
            letterSpacing: 0.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Personal bests section — flat rows
// ---------------------------------------------------------------------------

class _PersonalBestsSection extends StatelessWidget {
  const _PersonalBestsSection({required this.stats});
  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CrosscueSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('PERSONAL BESTS'),
          const SizedBox(height: 10),
          if (stats.personalBestMiniMs != null) ...[
            _PBRow(label: 'Mini (≤7×7)', value: _formatMs(stats.personalBestMiniMs!)),
            const _RowDivider(),
          ],
          if (stats.personalBest15x15Ms != null) ...[
            _PBRow(label: '15×15', value: _formatMs(stats.personalBest15x15Ms!)),
            const _RowDivider(),
          ],
          if (stats.personalBest21x21Ms != null)
            _PBRow(label: '21×21', value: _formatMs(stats.personalBest21x21Ms!)),
        ],
      ),
    );
  }
}

class _PBRow extends StatelessWidget {
  const _PBRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: CrosscueTypography.body,
              color: CrosscueColors.onSurface2Light,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: CrosscueTypography.robotoMono,
              fontSize: CrosscueTypography.body,
              fontWeight: FontWeight.w700,
              color: CrosscueColors.onSurface1Light,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Completion section — single row
// ---------------------------------------------------------------------------

class _CompletionSection extends StatelessWidget {
  const _CompletionSection({required this.stats});
  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.completionRate * 100).round();
    return Padding(
      padding: const EdgeInsets.all(CrosscueSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('COMPLETION'),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Completion rate',
                style: TextStyle(
                  fontSize: CrosscueTypography.body,
                  color: CrosscueColors.onSurface2Light,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: CrosscueColors.onSurface1Light,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  Text(
                    '${stats.totalSolved + stats.revealedCount} of ${stats.startedCount} started',
                    style: const TextStyle(
                      fontSize: CrosscueTypography.label,
                      color: CrosscueColors.onSurface3Light,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: CrosscueColors.onSurface3Light,
        letterSpacing: 1.0,
        height: 1.2,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: CrosscueColors.dividerLight);
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: CrosscueColors.dividerLight);
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 56, color: CrosscueColors.dividerLight);
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No stats yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Solve a puzzle to start tracking your stats.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatMs(int ms) {
  final total = ms ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}
