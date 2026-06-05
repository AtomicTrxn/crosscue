import 'dart:convert';

import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Web-application OAuth client ID, injected at build time via
/// `--dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=<id>` (see
/// `docs/architecture/sync-googledrive-setup.md`). Because the project doesn't
/// ship a `google-services.json`, `google_sign_in` on Android needs the *web*
/// client ID as `serverClientId` for `authenticate()` to work. It's empty when
/// unset — and the transport then stays inert (sign-in fails gracefully). The
/// web client ID is not a secret (it's embedded in every shipped app).
const String _serverClientIdFromEnv =
    String.fromEnvironment('GOOGLE_OAUTH_SERVER_CLIENT_ID');

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
/// Unlike iCloud (ambient sign-in), this transport reports
/// [supportsInteractiveSignIn] = true and implements [signIn] as a Google
/// sign-in + Drive AppData authorization prompt. The orchestrator's `enable()`
/// drives it; the silent `account()` path keeps the transport signed-out and
/// inert until then.
class GoogleDriveSyncTransport implements SyncTransport {
  GoogleDriveSyncTransport({
    Future<drive.DriveApi?> Function()? driveApiProvider,
    String serverClientId = _serverClientIdFromEnv,
  })  : _driveApiOverride = driveApiProvider,
        _serverClientId = serverClientId.isEmpty ? null : serverClientId;

  /// Test seam: lets a test supply a `DriveApi` backed by a mock HTTP client
  /// instead of going through real Google sign-in.
  final Future<drive.DriveApi?> Function()? _driveApiOverride;

  /// Web OAuth client ID passed to `GoogleSignIn.initialize` as
  /// `serverClientId`. Null when unconfigured → sign-in fails gracefully.
  final String? _serverClientId;

  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];
  static const String _space = 'appDataFolder';

  /// The signed-in account, cached for the life of the transport. Without this
  /// every Drive operation would re-run authentication — and since a single
  /// sync pass makes dozens of CRUD calls, the Android sign-in sheet would pop
  /// over and over in a loop. Cache it once; reuse it for every op.
  GoogleSignInAccount? _account;
  bool _initialized = false;
  bool _restoreAttempted = false;

  Future<void> _initialize() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  SyncAccount _toSyncAccount(GoogleSignInAccount account) => SyncAccount(
        provider: SyncProvider.googleDrive,
        displayName: account.email,
        id: account.id,
      );

  /// Silently restores a previously-authorized session — **no interactive UI**.
  /// Returns the account only when Drive authorization is already granted
  /// without prompting (the silent `authorizationForScopes`, not the
  /// interactive `authorizeScopes`). Caches the result. Used by [account] and as
  /// the fast path in [signIn] so launches and re-toggles don't re-prompt.
  Future<GoogleSignInAccount?> _restoreSilently() async {
    if (_account != null) return _account;
    // Attempt the (silent) lightweight restore at most once per app session, so
    // even if the platform surfaces a brief chooser it can never appear more
    // than once — and a failed restore never re-prompts.
    if (_restoreAttempted) return null;
    _restoreAttempted = true;
    await _initialize();
    final restored =
        await GoogleSignIn.instance.attemptLightweightAuthentication();
    if (restored == null) return null;
    final authz =
        await restored.authorizationClient.authorizationForScopes(_scopes);
    if (authz == null) return null;
    _account = restored;
    return restored;
  }

  /// Silent account check (no interactive UI). The toggle's "available" gate
  /// uses [supportsInteractiveSignIn], so a null here before sign-in is fine.
  /// Never authenticates interactively, and the CRUD path uses [_driveApi]'s
  /// cached account — so a sync pass can never trigger sign-in UI.
  @override
  Future<SyncAccount?> account() async {
    try {
      final restored = await _restoreSilently();
      return restored == null ? null : _toSyncAccount(restored);
    } on Object {
      return null;
    }
  }

  @override
  bool get supportsInteractiveSignIn => _serverClientId != null;

  /// Google sign-in + Drive AppData authorization. Called by the orchestrator's
  /// `enable()` — both on the user's toggle and on the boot-time re-enable.
  ///
  /// Tries a silent restore first so we don't pop the Google sheet on every
  /// launch; only prompts interactively when there's no recoverable session.
  @override
  Future<SyncAccount?> signIn() async {
    try {
      if (_serverClientId == null) return null;
      // Reuse an already-authorized session silently (boot re-enable, or a
      // toggle while still signed in) — no prompt in that case.
      final silent = await _restoreSilently();
      if (silent != null) return _toSyncAccount(silent);
      // No recoverable session → full interactive sign-in + authorization.
      await _initialize();
      final account =
          await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      await account.authorizationClient.authorizeScopes(_scopes);
      _account = account;
      return _toSyncAccount(account);
    } on Object {
      return null;
    }
  }

  Future<drive.DriveApi?> _driveApi() async {
    if (_driveApiOverride != null) return _driveApiOverride();
    // Cached session only — never authenticates here, so CRUD never pops UI.
    final account = _account;
    if (account == null) return null;
    try {
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
