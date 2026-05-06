import '../models/stats_data.dart';

/// Abstract contract for the stats data layer.
abstract class StatsRepository {
  /// Returns aggregated solve statistics for the current user.
  Future<StatsData> getStats();
}
