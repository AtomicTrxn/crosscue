/// Cloud account currently linked to the sync orchestrator.
///
/// Provider details (iCloud account token, Google email, etc.) are kept
/// opaque — the UI just needs to show *some* human-readable label and
/// recognise which provider the user is signed into.
class SyncAccount {
  const SyncAccount({
    required this.provider,
    required this.displayName,
    this.id,
  });

  final SyncProvider provider;
  final String displayName;

  /// Provider-specific stable identifier (Apple iCloud token, Google
  /// account sub). May be null on iCloud where the token is rotated.
  final String? id;
}

enum SyncProvider { iCloud, googleDrive, fake }
