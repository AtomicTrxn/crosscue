import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';

/// In-memory transport. Backed by a shared `Map<String, String>` so two
/// `FakeSyncTransport` instances pointing at the same store simulate two
/// devices talking to the same cloud bucket.
///
/// Tests own the store instance and pass it to both ends; production code
/// never instantiates this class.
class FakeSyncTransport implements SyncTransport {
  FakeSyncTransport({
    required this.store,
    SyncAccount? account,
  }) : _account = account ??
            const SyncAccount(
              provider: SyncProvider.fake,
              displayName: 'fake',
            );

  /// Backing storage shared across instances. Key → encoded blob bytes.
  final Map<String, String> store;
  final SyncAccount? _account;

  @override
  Future<SyncAccount?> account() async => _account;

  @override
  Future<List<String>> list(String prefix) async =>
      store.keys.where((k) => k.startsWith(prefix)).toList();

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<String?> write(String key, String bytes, {String? ifMatch}) async {
    store[key] = bytes;
    return null;
  }

  @override
  Future<void> delete(String key) async {
    store.remove(key);
  }
}
