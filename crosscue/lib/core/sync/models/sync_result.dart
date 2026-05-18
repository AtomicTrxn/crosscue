/// Outcome of a single [SyncOrchestrator.syncNow] call. Used by the sync
/// settings screen to surface "Last synced … · X pushed · Y pulled".
class SyncResult {
  const SyncResult({
    required this.pushed,
    required this.pulled,
    required this.conflicts,
    required this.duration,
  });

  static const SyncResult zero = SyncResult(
    pushed: 0,
    pulled: 0,
    conflicts: 0,
    duration: Duration.zero,
  );

  /// Total entities written to the transport across all namespaces.
  final int pushed;

  /// Total entities applied to the local DB across all namespaces.
  final int pulled;

  /// Conflicts the merge strategy resolved (best-progress overrides etc.).
  /// A non-zero value is informational, not an error.
  final int conflicts;

  final Duration duration;

  SyncResult operator +(SyncResult other) => SyncResult(
        pushed: pushed + other.pushed,
        pulled: pulled + other.pulled,
        conflicts: conflicts + other.conflicts,
        duration: duration + other.duration,
      );
}
