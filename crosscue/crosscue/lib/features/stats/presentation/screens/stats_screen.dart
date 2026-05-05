import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
// Body
// ---------------------------------------------------------------------------

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ── Streak ────────────────────────────────────────────────────────
        const _SectionHeader('Streak'),
        _StreakCard(stats: stats),
        const SizedBox(height: 8),

        // ── Totals ────────────────────────────────────────────────────────
        const _SectionHeader('Solves'),
        _TotalsCard(stats: stats),
        const SizedBox(height: 8),

        // ── Times ────────────────────────────────────────────────────────
        if (stats.hasSolves) ...[
          const _SectionHeader('Times'),
          _TimesCard(stats: stats),
          const SizedBox(height: 8),
        ],

        // ── Personal Bests ───────────────────────────────────────────────
        if (_hasPB(stats)) ...[
          const _SectionHeader('Personal Bests'),
          _PersonalBestsCard(stats: stats),
          const SizedBox(height: 8),
        ],

        // ── Completion Rate ───────────────────────────────────────────────
        const _SectionHeader('Completion'),
        _CompletionCard(stats: stats),
        const SizedBox(height: 16),
      ],
    );
  }

  static bool _hasPB(StatsData s) =>
      s.personalBest15x15Ms != null ||
      s.personalBest21x21Ms != null ||
      s.personalBestMiniMs != null;
}

// ---------------------------------------------------------------------------
// Streak card
// ---------------------------------------------------------------------------

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orange,
              value: '${stats.currentStreak}',
              label: 'Current streak',
              suffix: stats.currentStreak == 1 ? 'day' : 'days',
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _StatCell(
              icon: Icons.emoji_events_outlined,
              iconColor: Colors.amber,
              value: '${stats.longestStreak}',
              label: 'Longest streak',
              suffix: stats.longestStreak == 1 ? 'day' : 'days',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Totals card
// ---------------------------------------------------------------------------

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _StatRow(
            label: 'Total solved',
            value: '${stats.totalSolved}',
          ),
          _Divider(),
          _StatRow(
            label: 'Clean solves',
            value: '${stats.cleanSolves}',
            sublabel: stats.totalSolved > 0
                ? '${(stats.cleanSolves / stats.totalSolved * 100).round()}%'
                : null,
          ),
          _Divider(),
          _StatRow(
            label: 'Solved with help',
            value: '${stats.hintedCheckedSolves}',
          ),
          _Divider(),
          _StatRow(
            label: 'Puzzles revealed',
            value: '${stats.revealedCount}',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Times card
// ---------------------------------------------------------------------------

class _TimesCard extends StatelessWidget {
  const _TimesCard({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          if (stats.averageElapsedMs != null) ...[
            _StatRow(
              label: 'Average time',
              value: _formatMs(stats.averageElapsedMs!),
            ),
            _Divider(),
          ],
          if (stats.sevenDayAverageMs != null)
            _StatRow(
              label: '7-day average',
              value: _formatMs(stats.sevenDayAverageMs!),
            )
          else
            const _StatRow(
              label: '7-day average',
              value: '–',
              sublabel: 'No solves in the last 7 days',
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Personal bests card
// ---------------------------------------------------------------------------

class _PersonalBestsCard extends StatelessWidget {
  const _PersonalBestsCard({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (stats.personalBestMiniMs != null) {
      rows.add(_StatRow(
          label: 'Mini best', value: _formatMs(stats.personalBestMiniMs!)));
    }
    if (stats.personalBest15x15Ms != null) {
      if (rows.isNotEmpty) rows.add(_Divider());
      rows.add(_StatRow(
          label: '15×15 best',
          value: _formatMs(stats.personalBest15x15Ms!)));
    }
    if (stats.personalBest21x21Ms != null) {
      if (rows.isNotEmpty) rows.add(_Divider());
      rows.add(_StatRow(
          label: '21×21 best',
          value: _formatMs(stats.personalBest21x21Ms!)));
    }
    return _Card(child: Column(children: rows));
  }
}

// ---------------------------------------------------------------------------
// Completion card
// ---------------------------------------------------------------------------

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.stats});

  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.completionRate * 100).round();
    return _Card(
      child: Column(
        children: [
          _StatRow(
            label: 'Completion rate',
            value: '$pct%',
            sublabel: '${stats.totalSolved + stats.revealedCount}'
                ' of ${stats.startedCount} started',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.sublabel,
  });

  final String label;
  final String value;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.bodyMedium),
              if (sublabel != null)
                Text(sublabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        )),
            ],
          ),
          Text(value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.suffix,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          if (suffix != null)
            Text(suffix!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16);
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

/// Formats [ms] as m:ss (or h:mm:ss if ≥ 1 hour).
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
