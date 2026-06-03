import 'dart:convert';

import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Google Drive transport for Android — the Android counterpart to
/// [ICloudSyncTransport]. Stores each named blob as a file in the app's
/// **AppData** folder (`appDataFolder`): a hidden, per-app space that never
/// appears in the user's Drive UI and needs no file picker.
///
/// Like the iCloud transport, every method **fails gracefully**: if the user
/// isn't signed in — or the Google Cloud OAuth client hasn't been configured
/// yet (see `docs/architecture/sync-googledrive-setup.md`) — [account] returns
/// null (orchestrator stays in `SyncSignedOut`) and the CRUD methods become
/// no-ops. So it's safe to wire on Android before any of that is set up.
///
/// The interactive [signIn] is intentionally **not** on [SyncTransport] (iCloud
/// has no app-driven sign-in — it's ambient). The UI that triggers it for
/// Android is a follow-up to the shared sync UI (#142); until then `account()`'s
/// silent path keeps the transport signed-out and inert.
class GoogleDriveSyncTransport implements SyncTransport {
  GoogleDriveSyncTransport({
    Future<drive.DriveApi?> Function()? driveApiProvider,
  }) : _driveApiOverride = driveApiProvider;

  /// Test seam: lets a test supply a `DriveApi` backed by a mock HTTP client
  /// instead of going through real Google sign-in.
  final Future<drive.DriveApi?> Function()? _driveApiOverride;

  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];
  static const String _space = 'appDataFolder';

  Future<GoogleSignInAccount?> _silentAccount() async {
    try {
      await GoogleSignIn.instance.initialize();
      return await GoogleSignIn.instance.attemptLightweightAuthentication();
    } on Object {
      return null;
    }
  }

  SyncAccount _toSyncAccount(GoogleSignInAccount account) => SyncAccount(
        provider: SyncProvider.googleDrive,
        displayName: account.email,
        id: account.id,
      );

  @override
  Future<SyncAccount?> account() async {
    final account = await _silentAccount();
    return account == null ? null : _toSyncAccount(account);
  }

  /// Interactive Google sign-in + Drive AppData authorization. Wired by the
  /// Android sync-UI follow-up; not part of the [SyncTransport] interface.
  Future<SyncAccount?> signIn() async {
    try {
      await GoogleSignIn.instance.initialize();
      final account =
          await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      await account.authorizationClient.authorizeScopes(_scopes);
      return _toSyncAccount(account);
    } on Object {
      return null;
    }
  }

  Future<drive.DriveApi?> _driveApi() async {
    if (_driveApiOverride != null) return _driveApiOverride();
    try {
      final account = await _silentAccount();
      if (account == null) return null;
      final authz =
          await account.authorizationClient.authorizationForScopes(_scopes);
      if (authz == null) return null;
      return drive.DriveApi(authz.authClient(scopes: _scopes));
    } on Object {
      return null;
    }
  }

  Future<drive.File?> _fileByName(drive.DriveApi api, String name) async {
    final escaped = name.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    final res = await api.files.list(
      spaces: _space,
      q: "name = '$escaped' and trashed = false",
      $fields: 'files(id,name)',
      pageSize: 1,
    );
    final files = res.files;
    return (files == null || files.isEmpty) ? null : files.first;
  }

  @override
  Future<List<String>> list(String prefix) async {
    final api = await _driveApi();
    if (api == null) return const [];
    try {
      final res = await api.files.list(
        spaces: _space,
        $fields: 'files(name)',
        pageSize: 1000,
      );
      return (res.files ?? const <drive.File>[])
          .map((f) => f.name)
          .whereType<String>()
          .where((name) => name.startsWith(prefix))
          .toList();
    } on Object {
      return const [];
    }
  }

  @override
  Future<String?> read(String key) async {
    final api = await _driveApi();
    if (api == null) return null;
    try {
      final file = await _fileByName(api, key);
      final id = file?.id;
      if (id == null) return null;
      final media = await api.files.get(
        id,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes);
    } on Object {
      return null;
    }
  }

  @override
  Future<String?> write(String key, String bytes, {String? ifMatch}) async {
    final api = await _driveApi();
    if (api == null) return null;
    try {
      final data = utf8.encode(bytes);
      final media = drive.Media(
        Stream<List<int>>.value(data),
        data.length,
        contentType: 'application/octet-stream',
      );
      final existing = await _fileByName(api, key);
      final existingId = existing?.id;
      if (existingId != null) {
        final updated = await api.files
            .update(drive.File(), existingId, uploadMedia: media);
        return updated.headRevisionId;
      }
      final created = await api.files.create(
        drive.File(name: key, parents: const [_space]),
        uploadMedia: media,
      );
      return created.headRevisionId;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    final api = await _driveApi();
    if (api == null) return;
    try {
      final file = await _fileByName(api, key);
      final id = file?.id;
      if (id != null) await api.files.delete(id);
    } on Object {
      return;
    }
  }
}
