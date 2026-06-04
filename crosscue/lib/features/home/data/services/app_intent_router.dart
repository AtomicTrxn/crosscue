import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/domain/repositories/archive_repository.dart';

/// App Group key the iOS App Intents (`ios/Runner/CrosscueAppIntents.swift`)
/// write a pending route *token* into. The app reads + clears it on launch and
/// resume and navigates accordingly. See issue #115.
const String kPendingIntentRouteKey = 'pendingIntentRoute';

/// Resolves an App-Intent route token into a go_router path, or `null` when it
/// can't be resolved (the caller then navigates nowhere).
///
/// **Additive by design** (see #115): the resolver is not a closed enum — any
/// token starting with `/` is treated as a literal go_router path and passes
/// straight through, so a future intent can target e.g. `/leaderboard/daily`
/// with no change here. Only the few app-state-dependent tokens (`today`,
/// `continue`) are resolved against the archive.
Future<String?> resolveAppIntentRoute(
  String token, {
  required ArchiveRepository archive,
}) async {
  final t = token.trim();
  if (t.isEmpty) return null;
  // Literal go_router path — pass through unchanged (additive contract).
  if (t.startsWith('/')) return t;

  switch (t) {
    case 'stats':
      return Routes.stats;
    case 'today':
      // Today's puzzle = the most-recently-imported one (matches the home
      // "featured" selection and the widget).
      final entries = await archive.getArchiveEntries();
      final today = entries.isEmpty ? null : entries.first;
      return today == null
          ? Routes.home
          : Routes.solveFor(Uri.encodeComponent(today.puzzleId));
    case 'continue':
      final entry = _mostRecentInProgress(await archive.getArchiveEntries());
      return entry == null
          ? Routes.archive
          : Routes.solveFor(Uri.encodeComponent(entry.puzzleId));
    default:
      return null;
  }
}

ArchiveEntry? _mostRecentInProgress(List<ArchiveEntry> entries) {
  final inProgress = entries.where((e) => e.isInProgress).toList();
  if (inProgress.isEmpty) return null;
  inProgress.sort((a, b) {
    final at = a.lastPlayedAt ?? a.importedAt;
    final bt = b.lastPlayedAt ?? b.importedAt;
    return bt.compareTo(at); // most-recently-played first
  });
  return inProgress.first;
}
