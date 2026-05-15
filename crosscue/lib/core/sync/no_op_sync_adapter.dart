import 'package:crosscue/core/sync/sync_adapter.dart';

/// No-op sync adapter. All puzzles stay local; no backend involved.
class NoOpSyncAdapter implements SyncAdapter {
  const NoOpSyncAdapter();

  @override
  Future<void> sync() async {}

  @override
  Future<bool> get isSyncEnabled async => false;
}
