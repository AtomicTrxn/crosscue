import 'dart:convert';

import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/stats/domain/repositories/stats_repository.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_service.g.dart';

/// Schema version of the App Group payload. Bump only on a breaking change to
/// the JSON shape; additive fields (like `leaderboard`) don't require a bump.
const int kHomeWidgetSchemaVersion = 1;

/// Builds the versioned payload the iOS WidgetKit extension reads from the
/// shared App Group container.
///
/// **Additive by design** (see issue #114): the `leaderboard` slot is `null`
/// today and becomes `{rank, total, percentile}` once #111's implementation
/// lands — same key, new shape, the widget reads it as an optional row. No
/// schema migration and no widget rebuild required.
Map<String, Object?> buildHomeWidgetPayload({
  required int currentStreak,
  required int bestStreak,
  PuzzleMetadata? today,
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
          },
    'leaderboard': null,
  };
}

/// Pushes glanceable state (current streak + today's puzzle) into the iOS App
/// Group container so the WidgetKit extension can render it on the Home and
/// Lock screens.
///
/// Safe to call before the widget extension + App Group are configured (see
/// `docs/architecture/ios-widget-setup.md`): every failure is swallowed, so the
/// app behaves identically whether or not the widget exists yet. No-op on
/// platforms without a widget (Android Glance parity is a separate issue).
class HomeWidgetService {
  HomeWidgetService({
    required StatsRepository stats,
    required ImportRepository puzzles,
  })  : _stats = stats,
        _puzzles = puzzles;

  final StatsRepository _stats;
  final ImportRepository _puzzles;

  /// App Group shared between the Runner app and the widget extension. Must
  /// match the identifier registered in the Apple Developer portal and set on
  /// both targets' App Group entitlement.
  static const String appGroupId = 'group.dev.tomhess.crosscue';

  /// The WidgetKit widget kind — the `iOSName` passed to `updateWidget`, and
  /// the struct name in the Swift extension.
  static const String iOSWidgetName = 'CrosscueWidget';

  /// Key the JSON payload is stored under in the App Group container.
  static const String dataKey = 'crosscue_widget_v1';

  /// Gathers the current streak + today's puzzle and pushes them to the widget.
  Future<void> refresh() async {
    try {
      final stats = await _stats.getStats();
      final today = _mostRecent(await _puzzles.getAllMetadata());
      final payload = buildHomeWidgetPayload(
        currentStreak: stats.currentStreak,
        bestStreak: stats.longestStreak,
        today: today,
      );
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData<String>(dataKey, jsonEncode(payload));
      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    } on Object {
      // Inert until the widget extension + App Group are configured. This is
      // the documented "ships safely before platform setup" behavior.
    }
  }

  /// Today's puzzle = the most recently imported one (matches the home screen's
  /// "featured" selection). Null when the library is empty.
  static PuzzleMetadata? _mostRecent(List<PuzzleMetadata> metas) {
    if (metas.isEmpty) return null;
    return metas.reduce(
      (a, b) => a.importedAt.isAfter(b.importedAt) ? a : b,
    );
  }
}

@Riverpod(keepAlive: true)
HomeWidgetService homeWidgetService(Ref ref) => HomeWidgetService(
      stats: ref.watch(statsRepositoryProvider),
      puzzles: ref.watch(importRepositoryProvider),
    );
