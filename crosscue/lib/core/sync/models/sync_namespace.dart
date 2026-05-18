/// The four sync namespaces. Each maps to a blob prefix on the transport
/// and to a [NamespaceSyncAdapter] that owns its merge/serialize logic.
enum SyncNamespace {
  puzzles('puzzles/'),
  sessions('sessions/'),
  completions('completions/'),
  settings('settings/');

  const SyncNamespace(this.prefix);

  /// Blob-key prefix on the transport (includes the trailing slash).
  final String prefix;
}
