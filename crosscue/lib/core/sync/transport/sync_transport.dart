import 'package:crosscue/core/sync/models/sync_account.dart';

/// Tiny CRUD-on-named-blobs abstraction every platform must implement.
///
/// All keys are flat strings using the namespace prefixes defined in
/// `SyncNamespace`. See `docs/architecture/sync-design.md`.
abstract class SyncTransport {
  /// The currently linked account, or null if not signed in.
  Future<SyncAccount?> account();

  /// Returns the keys currently present under [prefix] (without filtering
  /// out anything). Empty list when the prefix has no blobs.
  Future<List<String>> list(String prefix);

  /// Returns the encoded blob bytes for [key], or null if missing.
  Future<String?> read(String key);

  /// Writes [bytes] to [key]. [ifMatch] is an optional optimistic-concurrency
  /// token returned by an earlier read/list — implementations that don't
  /// support ETags may ignore it. Returns the new token (or null).
  Future<String?> write(String key, String bytes, {String? ifMatch});

  /// Removes [key] if present. No-op when missing.
  Future<void> delete(String key);
}
