import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';

/// No-op transport. Reports no account and accepts no writes; everything
/// stays on the device. Wired as the default until the iCloud / Drive
/// transports land — see `docs/architecture/sync-progress.md`.
class NoOpSyncTransport implements SyncTransport {
  const NoOpSyncTransport();

  @override
  Future<SyncAccount?> account() async => null;

  @override
  Future<List<String>> list(String prefix) async => const [];

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<String?> write(String key, String bytes, {String? ifMatch}) async =>
      null;

  @override
  Future<void> delete(String key) async {}
}
