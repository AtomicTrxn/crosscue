import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:crosscue/core/sync/models/sync_manifest.dart';
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

/// Outcome of an adapter [NamespaceSyncAdapter.pull].
class PullResult {
  const PullResult({
    this.outcome = NamespaceSyncOutcome.zero,
    this.seen = const {},
    this.caughtUp = const {},
    this.newerSchemaSeen,
  });

  static const PullResult zero = PullResult();

  final NamespaceSyncOutcome outcome;

  /// Highest envelope schema version observed that is newer than this build's
  /// [SyncBlob.currentSchemaVersion], or null when none was. A non-null value
  /// triggers the ADR-0016 mixed-version guard: the orchestrator suspends
  /// pushes to this namespace and surfaces an "update Crosscue" notice.
  final int? newerSchemaSeen;

  /// Every remote key we successfully decoded this pass, with the metadata read
  /// from the blob. Used to (re)build the manifest on the fallback path.
  final Map<String, SyncManifestEntry> seen;

  /// Keys we fully reconciled — applied **or** deliberately kept local. The
  /// orchestrator advances the local cursor for these. A key skipped for a
  /// missing parent FK or a decode/read failure is intentionally absent so the
  /// next pass retries it (its manifest entry still won't match the cursor).
  final Map<String, SyncManifestEntry> caughtUp;

  int get pulled => outcome.pulled;
  int get conflicts => outcome.conflicts;
}

/// Outcome of an adapter [NamespaceSyncAdapter.push].
class PushResult {
  const PushResult({
    this.outcome = NamespaceSyncOutcome.zero,
    this.written = const {},
  });

  static const PushResult zero = PushResult();

  final NamespaceSyncOutcome outcome;

  /// Keys we wrote this pass, with the metadata we wrote, so the orchestrator
  /// can fold them into the manifest and advance our own cursor (avoiding a
  /// re-pull of our own upload next pass).
  final Map<String, SyncManifestEntry> written;

  int get pushed => outcome.pushed;
}

/// Builds the manifest index entry for a decoded blob.
SyncManifestEntry manifestEntryFor(SyncBlob blob) => SyncManifestEntry(
      syncVersion: blob.syncVersion,
      updatedAt: blob.updatedAt,
      deviceId: blob.deviceId,
    );

/// Per-namespace sync logic. The orchestrator calls [pull] then [push] on each
/// adapter once per sync pass. Implementations encapsulate the merge rules for
/// their namespace (see issue #189 for the manifest-assisted incremental flow).
abstract class NamespaceSyncAdapter {
  SyncNamespace get namespace;

  /// Downloads remote entities and applies them locally.
  ///
  /// When [onlyKeys] is null the adapter lists and scans the whole namespace
  /// (the fallback / first-sync path). Otherwise it reads only the given keys —
  /// the incremental path, where the orchestrator has already diffed the remote
  /// manifest against local cursors and knows exactly what changed.
  Future<PullResult> pull(
    SyncTransport transport, {
    Iterable<String>? onlyKeys,
  });

  /// Uploads local entities the cloud doesn't yet have.
  ///
  /// [remoteIndex], when provided, is the manifest's view of this namespace's
  /// remote keys; the adapter trusts it to skip remote metadata probes
  /// (`list`/`read`). When null the adapter probes the transport directly —
  /// used by lower-level unit tests and as a safe fallback.
  Future<PushResult> push(
    SyncTransport transport,
    String deviceId, {
    Map<String, SyncManifestEntry>? remoteIndex,
  });

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
