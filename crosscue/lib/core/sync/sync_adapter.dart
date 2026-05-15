/// Abstract sync adapter. The shipping build is local-only and wires
/// [NoOpSyncAdapter]; the interface exists so a remote implementation can be
/// dropped in later without changing callers.
abstract class SyncAdapter {
  Future<void> sync();
  Future<bool> get isSyncEnabled;
}
