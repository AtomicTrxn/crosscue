/// Abstract sync adapter. Phase 1 uses NoOpSyncAdapter (local-only).
/// Phase 2+ will replace with a real implementation without changing callers.
abstract class SyncAdapter {
  Future<void> sync();
  Future<bool> get isSyncEnabled;
}
