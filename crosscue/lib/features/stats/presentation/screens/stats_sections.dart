part of 'stats_screen.dart';

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

        // ── Difficulty ────────────────────────────────────────────────────
        if (_hasDifficultyData(stats)) ...[
          _DifficultySection(stats: stats),
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

  static bool _hasDifficultyData(StatsData s) =>
      s.difficultyBreakdown.values.fold<int>(0, (sum, count) => sum + count) >=
      3;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'STREAK',
            style: _sectionLabelStyle.copyWith(
              color: context.crosscueOnSurface3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
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
                color: context.crosscueDivider,
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
          style: _sectionLabelStyle.copyWith(
            color: context.crosscueOnSurface3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: _largeStatValueStyle.copyWith(
            color: context.crosscueOnSurface1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: _labelStyle.copyWith(
            color: context.crosscueOnSurface3,
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
                      ? formatMs(stats.averageElapsedMs!)
                      : '–',
                  label: 'AVG ALL',
                  sub: 'overall',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _TimeCell(
                  value: stats.sevenDayAverageMs != null
                      ? formatMs(stats.sevenDayAverageMs!)
                      : '–',
                  label: '7-DAY AVG',
                  sub: 'last 7 days',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _TimeCell(
                  value: _bestTime(stats),
                  label: 'BEST',
                  sub: 'all time',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Returns the best (lowest) personal best across all puzzle sizes, formatted.
String _bestTime(StatsData stats) {
  final candidates = [
    stats.personalBestMiniMs,
    stats.personalBest15x15Ms,
    stats.personalBest21x21Ms,
  ].whereType<int>();
  if (candidates.isEmpty) return '–';
  return formatMs(candidates.reduce((a, b) => a < b ? a : b));
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
          style: _timeValueStyle.copyWith(
            color: context.crosscueOnSurface1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style:
              _primaryStatLabelStyle.copyWith(color: context.crosscuePrimary),
        ),
        Text(
          sub,
          style: _tinyLabelStyle.copyWith(
            color: context.crosscueOnSurface3,
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
          style: _mediumStatValueStyle.copyWith(
            color: context.crosscueOnSurface1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: _smallLabelStyle.copyWith(
            color: context.crosscueOnSurface3,
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
            _PBRow(
              label: 'Mini (≤7×7)',
              value: formatMs(stats.personalBestMiniMs!),
            ),
            const _RowDivider(),
          ],
          if (stats.personalBest15x15Ms != null) ...[
            _PBRow(label: '15×15', value: formatMs(stats.personalBest15x15Ms!)),
            const _RowDivider(),
          ],
          if (stats.personalBest21x21Ms != null)
            _PBRow(label: '21×21', value: formatMs(stats.personalBest21x21Ms!)),
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
            style: _bodyStyle.copyWith(
              color: context.crosscueOnSurface2,
            ),
          ),
          Text(
            value,
            style: _monoBodyValueStyle.copyWith(
              color: context.crosscueOnSurface1,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Difficulty section
// ---------------------------------------------------------------------------

class _DifficultySection extends StatelessWidget {
  const _DifficultySection({required this.stats});
  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    final rows = [
      const _DifficultyRowData('Easy', 'easy', Color(0xFF4CAF50)),
      const _DifficultyRowData('Medium', 'medium', CrosscueColors.primary),
      const _DifficultyRowData('Hard', 'hard', Color(0xFFFF9800)),
      _DifficultyRowData('Themeless', 'themeless', context.crosscueOnSurface3),
    ];
    final total = stats.difficultyBreakdown.values
        .fold<int>(0, (sum, count) => sum + count);
    if (total < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(CrosscueSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('DIFFICULTY'),
          const SizedBox(height: 14),
          for (final row in rows)
            _DifficultyBar(
              label: row.label,
              count: stats.difficultyBreakdown[row.key] ?? 0,
              total: total,
              color: row.color,
            ),
        ],
      ),
    );
  }
}

class _DifficultyBar extends StatelessWidget {
  const _DifficultyBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: _labelStyle.copyWith(
                color: context.crosscueOnSurface2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: context.crosscueDivider),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: ColoredBox(color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: _labelStyle.copyWith(
                color: context.crosscueOnSurface3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyRowData {
  const _DifficultyRowData(this.label, this.key, this.color);
  final String label;
  final String key;
  final Color color;
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
              Text(
                'Completion rate',
                style: _bodyStyle.copyWith(
                  color: context.crosscueOnSurface2,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: _mediumStatValueStyle.copyWith(
                      color: context.crosscueOnSurface1,
                    ),
                  ),
                  Text(
                    '${stats.totalSolved + stats.revealedCount} of ${stats.startedCount} started',
                    style: _labelStyle.copyWith(
                      color: context.crosscueOnSurface3,
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
      style: _sectionLabelStyle.copyWith(
        color: context.crosscueOnSurface3,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: context.crosscueDivider);
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: context.crosscueDivider);
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 56, color: context.crosscueDivider);
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
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: context.crosscueOnSurface3,
          ),
          const SizedBox(height: 16),
          Text('No stats yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Solve a puzzle to start tracking your stats.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.crosscueOnSurface3,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
