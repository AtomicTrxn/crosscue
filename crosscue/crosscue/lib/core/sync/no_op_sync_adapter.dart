import 'sync_adapter.dart';

/// Phase 1 no-op sync adapter. All puzzles stay local; no backend involved.
/// Replace with a real implementation in Phase 2 without changing callers.
class NoOpSyncAdapter implements SyncAdapter {
  const NoOpSyncAdapter();

  @override
  Future<void> sync() async {
    // No-op: local-only in Phase 1.
  }

  @override
  Future<bool> get isSyncEnabled async => false;
}
