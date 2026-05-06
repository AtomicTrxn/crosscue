import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/stats_repository_impl.dart';
import '../../domain/models/stats_data.dart';
import '../../domain/repositories/stats_repository.dart';

part 'stats_providers.g.dart';

/// Singleton repository for the Stats feature.
@Riverpod(keepAlive: true)
StatsRepository statsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return StatsRepositoryImpl(dao: db.statsDao);
}

/// Aggregated stats derived from all solve sessions.
/// Re-fetched each time the provider is watched (no keepAlive),
/// so opening the Stats tab always shows fresh data.
@riverpod
Future<StatsData> statsData(Ref ref) {
  return ref.watch(statsRepositoryProvider).getStats();
}
