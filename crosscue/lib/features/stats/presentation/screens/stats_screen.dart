import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/core/utils/time_format.dart';
import 'package:crosscue/features/stats/domain/models/stats_data.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'stats_sections.dart';

const _sectionLabelStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.0,
  height: 1.2,
);
const _primaryStatLabelStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);
const _largeStatValueStyle = TextStyle(
  fontSize: 40,
  fontWeight: FontWeight.w700,
  letterSpacing: -1,
  height: 1,
);
const _mediumStatValueStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
  height: 1,
);
const _timeValueStyle = TextStyle(
  fontFamily: CrosscueTypography.robotoMono,
  fontSize: 24,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
  height: 1,
);
const _monoBodyValueStyle = TextStyle(
  fontFamily: CrosscueTypography.robotoMono,
  fontSize: CrosscueTypography.body,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.5,
);
const _smallLabelStyle = TextStyle(
  fontSize: 11,
  letterSpacing: 0.6,
);
const _labelStyle = TextStyle(fontSize: CrosscueTypography.label);
const _bodyStyle = TextStyle(fontSize: CrosscueTypography.body);
const _tinyLabelStyle = TextStyle(fontSize: 10);

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
