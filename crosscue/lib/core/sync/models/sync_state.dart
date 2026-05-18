/// The orchestrator's lifecycle state. Sealed so consumers can switch
/// exhaustively. See `docs/architecture/sync-design.md` (API surface).
sealed class SyncState {
  const SyncState();
}

/// Sync feature is turned off by the user. Default state on first launch.
class SyncDisabled extends SyncState {
  const SyncDisabled();
}

/// Sync is enabled but no cloud account is currently linked — user must
/// finish sign-in (Google Drive) or turn on iCloud Drive for the app.
class SyncSignedOut extends SyncState {
  const SyncSignedOut();
}

/// Sync is enabled, signed in, not currently syncing.
class SyncIdle extends SyncState {
  const SyncIdle({this.lastSyncedAt});

  final DateTime? lastSyncedAt;
}

/// A sync pass is in flight.
class SyncRunning extends SyncState {
  const SyncRunning();
}

/// Last sync attempt failed. [transient] = true means the orchestrator will
/// retry automatically on the next trigger; false means the user must act
/// (re-sign-in, free quota, etc.).
class SyncError extends SyncState {
  const SyncError(this.message, {required this.transient});

  final String message;
  final bool transient;
}
