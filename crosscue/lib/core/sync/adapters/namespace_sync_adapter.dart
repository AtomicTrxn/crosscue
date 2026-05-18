import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';

/// Result of pushing or pulling one namespace.
class NamespaceSyncOutcome {
  const NamespaceSyncOutcome({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
  });

  static const NamespaceSyncOutcome zero = NamespaceSyncOutcome();

  final int pushed;
  final int pulled;
  final int conflicts;

  NamespaceSyncOutcome operator +(NamespaceSyncOutcome other) =>
      NamespaceSyncOutcome(
        pushed: pushed + other.pushed,
        pulled: pulled + other.pulled,
        conflicts: conflicts + other.conflicts,
      );
}

/// Per-namespace sync logic. The orchestrator calls [push] then [pull] on
/// each adapter once per sync pass. Implementations encapsulate the merge
/// rules described in `docs/architecture/sync-design.md` (Conflict resolution).
abstract class NamespaceSyncAdapter {
  SyncNamespace get namespace;

  /// Uploads local entities that the cloud doesn't yet have. Returns the
  /// number of blobs written.
  Future<NamespaceSyncOutcome> push(SyncTransport transport, String deviceId);

  /// Downloads remote entities and applies them locally. Returns the number
  /// of local rows mutated, plus a count of conflicts the merge resolved.
  Future<NamespaceSyncOutcome> pull(SyncTransport transport);

  /// Convenience: full blob key for a namespace-local id.
  String keyFor(String id) => '${namespace.prefix}$id.json';

  /// Convenience: extracts the id portion of a `puzzles/<id>.json` key.
  /// Returns null if the key doesn't look like one of ours.
  String? idFromKey(String key) {
    if (!key.startsWith(namespace.prefix)) return null;
    if (!key.endsWith('.json')) return null;
    return key.substring(namespace.prefix.length, key.length - '.json'.length);
  }
}
