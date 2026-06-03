import 'package:crosscue/core/sync/models/sync_account.dart';

/// Tiny CRUD-on-named-blobs abstraction every platform must implement.
///
/// All keys are flat strings using the namespace prefixes defined in
/// `SyncNamespace`. See `docs/architecture/sync-design.md`.
abstract class SyncTransport {
  /// The currently linked account, or null if not signed in. Non-interactive
  /// (silent) — never prompts.
  Future<SyncAccount?> account();

  /// Links an account, prompting interactively if the platform requires it
  /// (Google Drive). Ambient transports (iCloud) just resolve [account]. The
  /// orchestrator calls this from `enable()`.
  Future<SyncAccount?> signIn();

  /// Whether [signIn] shows an app-driven sign-in prompt (Google Drive) rather
  /// than relying on an ambient account (iCloud). Lets the UI allow enabling
  /// even when there's no account yet (the tap drives the sign-in).
  bool get supportsInteractiveSignIn;

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

/// Classifies a recoverable transport failure so the orchestrator can react
/// deliberately instead of mistaking it for "the blob isn't there."
///
/// The critical distinction: a missing blob is reported as `null`/empty (the
/// normal "we don't have it yet" signal), whereas an *access* failure throws a
/// [SyncTransportException]. If a lock/permission error were silently treated
/// as missing, the next pass would spuriously re-upload local state over the
/// remote it couldn't read. See issue #113.
enum SyncTransportErrorKind {
  /// Another device holds a conflicting file-coordination claim (iCloud) or the
  /// blob is otherwise temporarily unavailable. Transient — retry next trigger.
  locked,

  /// Cloud storage quota exceeded (or the local disk is full). Not transient —
  /// the user must free space.
  quotaExceeded,

  /// The app isn't permitted to read/write the cloud container. Not transient.
  permissionDenied,

  /// Any other I/O failure. Transient by default.
  io,
}

/// Thrown by a [SyncTransport] when an operation fails for a reason other than
/// the blob simply not existing. Carries a [kind] the orchestrator maps to a
/// `SyncError` (with the right `transient` flag).
class SyncTransportException implements Exception {
  const SyncTransportException(this.kind, {this.message});

  final SyncTransportErrorKind kind;
  final String? message;

  /// Whether the orchestrator should retry automatically on the next trigger
  /// (locked / generic I/O) rather than requiring the user to act
  /// (quota / permission).
  bool get isTransient =>
      kind == SyncTransportErrorKind.locked ||
      kind == SyncTransportErrorKind.io;

  @override
  String toString() => 'SyncTransportException(${kind.name}'
      '${message == null ? '' : ': $message'})';
}
