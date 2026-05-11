import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/features/stats/data/repositories/stats_repository_impl.dart';
import 'package:crosscue/features/stats/data/services/stats_export_service_impl.dart';
import 'package:crosscue/features/stats/domain/models/stats_data.dart';
import 'package:crosscue/features/stats/domain/repositories/stats_repository.dart';
import 'package:crosscue/features/stats/domain/services/stats_export_service.dart';

part 'stats_providers.g.dart';

/// Singleton repository for the Stats feature.
@Riverpod(keepAlive: true)
StatsRepository statsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return StatsRepositoryImpl(dao: db.statsDao);
}

/// Singleton export service — generates/parses JSON only; no file system.
@Riverpod(keepAlive: true)
StatsExportService statsExportService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return StatsExportServiceImpl(dao: db.statsDao);
}

/// Aggregated stats derived from all solve sessions.
/// Re-fetched each time the provider is watched (no keepAlive),
/// so opening the Stats tab always shows fresh data.
@riverpod
Future<StatsData> statsData(Ref ref) {
  return ref.watch(statsRepositoryProvider).getStats();
}
