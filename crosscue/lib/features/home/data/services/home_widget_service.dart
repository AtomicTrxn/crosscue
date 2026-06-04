import 'dart:convert';

import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/domain/repositories/archive_repository.dart';
import 'package:crosscue/features/archive/presentation/providers/archive_providers.dart';
import 'package:crosscue/features/stats/domain/repositories/stats_repository.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_service.g.dart';

/// Schema version of the App Group payload. Bump only on a breaking change to
/// the JSON shape; additive fields (like `leaderboard`, `today.status`) don't
/// require a bump.
const int kHomeWidgetSchemaVersion = 1;

/// Today's-puzzle solve state, surfaced on the widget so the user can see at a
/// glance whether they've done today's puzzle.
enum TodayStatus {
  /// Completed or fully revealed.
  solved('solved'),

  /// A session exists but isn't finished.
  inProgress('inProgress'),

  /// Imported/downloaded but not started.
  notStarted('new');

  const TodayStatus(this.wire);

  /// String written into the payload (read by the Swift widget).
  final String wire;
}

/// Builds the versioned payload the iOS WidgetKit extension reads from the
/// shared App Group container.
///
/// **Additive by design** (see issue #114): the `leaderboard` slot is `null`
/// today and becomes `{rank, total, percentile}` once #111's implementation
/// lands — same key, new shape, the widget reads it as an optional row. No
/// schema migration and no widget rebuild required. `today.status` is likewise
/// additive.
Map<String, Object?> buildHomeWidgetPayload({
  required int currentStreak,
  required int bestStreak,
  ({String id, String title, TodayStatus status})? today,
}) {
  return {
    'version': kHomeWidgetSchemaVersion,
    'streak': {'current': currentStreak, 'best': bestStreak},
    'today': today == null
        ? null
        : {
            'puzzleId': today.id,
            'title': today.title,
            'route': Routes.solveFor(Uri.encodeComponent(today.id)),
            'status': today.status.wire,
          },
    'leaderboard': null,
  };
}

/// Pushes glanceable state (current streak + today's puzzle + its solve state)
/// into the iOS App Group container so the WidgetKit extension can render it on
/// the Home and Lock screens.
///
/// Safe to call before the widget extension + App Group are configured (see
/// `docs/architecture/ios-widget-setup.md`): every failure is swallowed, so the
/// app behaves identically whether or not the widget exists yet. No-op on
/// platforms without a widget (Android Glance parity is a separate issue).
class HomeWidgetService {
  HomeWidgetService({
    required StatsRepository stats,
    required ArchiveRepository archive,
  })  : _stats = stats,
        _archive = archive;

  final StatsRepository _stats;
  final ArchiveRepository _archive;

  /// App Group shared between the Runner app and the widget extension. Must
  /// match the identifier registered in the Apple Developer portal and set on
  /// both targets' App Group entitlement.
  static const String appGroupId = 'group.dev.tomhess.crosscue';

  /// The WidgetKit widget kind — the `iOSName` passed to `updateWidget`, and
  /// the struct name in the Swift extension.
  static const String iOSWidgetName = 'CrosscueWidget';

  /// Key the JSON payload is stored under in the App Group container.
  static const String dataKey = 'crosscue_widget_v1';

  /// Gathers the current streak + today's puzzle (and its solve state) and
  /// pushes them to the widget.
  Future<void> refresh() async {
    try {
      final stats = await _stats.getStats();
      // Archive entries are ordered by import date desc, so the first is the
      // "featured"/today puzzle — same selection the home screen uses.
      final entries = await _archive.getArchiveEntries();
      final entry = entries.isEmpty ? null : entries.first;
      final payload = buildHomeWidgetPayload(
        currentStreak: stats.currentStreak,
        bestStreak: stats.longestStreak,
        today: entry == null
            ? null
            : (
                id: entry.puzzleId,
                title: entry.title,
                status: _statusOf(entry)
              ),
      );
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData<String>(dataKey, jsonEncode(payload));
      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    } on Object {
      // Inert until the widget extension + App Group are configured. This is
      // the documented "ships safely before platform setup" behavior.
    }
  }

  static TodayStatus _statusOf(ArchiveEntry e) {
    if (e.isCompleted || e.isRevealed) return TodayStatus.solved;
    if (e.isInProgress) return TodayStatus.inProgress;
    return TodayStatus.notStarted;
  }
}

@Riverpod(keepAlive: true)
HomeWidgetService homeWidgetService(Ref ref) => HomeWidgetService(
      stats: ref.watch(statsRepositoryProvider),
      archive: ref.watch(archiveRepositoryProvider),
    );
