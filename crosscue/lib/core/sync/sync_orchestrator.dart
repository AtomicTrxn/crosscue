import 'dart:async';
import 'dart:convert';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/adapters/completions_sync_adapter.dart';
import 'package:crosscue/core/sync/adapters/namespace_sync_adapter.dart';
import 'package:crosscue/core/sync/adapters/puzzles_sync_adapter.dart';
import 'package:crosscue/core/sync/adapters/sessions_sync_adapter.dart';
import 'package:crosscue/core/sync/adapters/settings_sync_adapter.dart';
import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/models/sync_manifest.dart';
import 'package:crosscue/core/sync/models/sync_result.dart';
import 'package:crosscue/core/sync/models/sync_state.dart';
import 'package:crosscue/core/sync/sync_manifest_store.dart';
import 'package:crosscue/core/sync/transport/no_op_sync_transport.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:crosscue/core/utils/uuid.dart';

/// Top-level facade exposed to the app. Owns the per-namespace adapters,
/// drives push-then-pull sync passes, and broadcasts lifecycle state to
/// the settings UI.
///
/// See `docs/architecture/sync-design.md` (High-level shape).
class SyncOrchestrator {
  SyncOrchestrator({
    required this.transport,
    required this.db,
    List<NamespaceSyncAdapter>? adapters,
    this.manifestStore = const SyncManifestStore(),
  }) : adapters = adapters ??
            <NamespaceSyncAdapter>[
              PuzzlesSyncAdapter(db),
              SessionsSyncAdapter(db),
              CompletionsSyncAdapter(db),
              SettingsSyncAdapter(db),
            ];

  final SyncTransport transport;
  final AppDatabase db;
  final List<NamespaceSyncAdapter> adapters;
  final SyncManifestStore manifestStore;

  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();
  SyncState _state = const SyncDisabled();
  DateTime? _lastSyncedAt;

  Stream<SyncState> get state => _stateController.stream;
  SyncState get currentState => _state;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<SyncAccount?> currentAccount() => transport.account();

  Future<void> enable() async {
    // signIn() prompts interactively on transports that need it (Google Drive)
    // and just resolves the ambient account on the rest (iCloud). A null result
    // means the user dismissed the prompt or isn't signed in — stay signed-out.
    final account = await transport.signIn();
    _setState(
      account == null
          ? const SyncSignedOut()
          : SyncIdle(lastSyncedAt: _lastSyncedAt),
    );
  }

  /// Boot/launch re-enable: restores an existing session **silently** via
  /// [SyncTransport.account] and never shows sign-in UI. Stays [SyncSignedOut]
  /// if nothing can be restored without a prompt — the user re-enables
  /// interactively from Settings. Use this on launch (and any non-user-initiated
  /// path); use [enable] only for an explicit opt-in.
  Future<void> enableSilently() async {
    final account = await transport.account();
    _setState(
      account == null
          ? const SyncSignedOut()
          : SyncIdle(lastSyncedAt: _lastSyncedAt),
    );
  }

  Future<void> disable({bool wipeRemote = false}) async {
    if (wipeRemote) {
      for (final adapter in adapters) {
        try {
          final keys = await transport.list(adapter.namespace.prefix);
          for (final key in keys) {
            await transport.delete(key);
          }
        } on SyncTransportException {
          // Best-effort wipe: a transient lock / I/O error on one namespace
          // must not abort turning sync off. The local copy is what matters
          // here; any leftover remote blobs are harmless and get cleaned on a
          // later disable.
        }
      }
      try {
        await transport.delete(SyncManifest.manifestKey);
      } on SyncTransportException {
        // Same best-effort semantics as namespace blobs: stale manifest data is
        // harmless if the remote wipe is interrupted.
      }
    }
    _setState(const SyncDisabled());
  }

  /// Runs a single push-then-pull pass across all namespaces. Safe to call
  /// when [SyncDisabled] or [SyncSignedOut] — it returns immediately with
  /// [SyncResult.zero] in those states.
  Future<SyncResult> syncNow() async {
    if (_state is SyncDisabled || _state is SyncSignedOut) {
      return SyncResult.zero;
    }
    // Coalesce overlapping triggers (e.g. app-resume and a just-completed
    // solve firing back-to-back): if a pass is already in flight, skip rather
    // than run a second concurrent push/pull.
    if (_state is SyncRunning) return SyncResult.zero;
    // NoOp transports report no account but are wired in the local-only
    // build. Short-circuit to avoid spurious writes/reads.
    if (transport is NoOpSyncTransport) return SyncResult.zero;

    _setState(const SyncRunning());
    final start = DateTime.now();
    final deviceId = await _resolveDeviceId();

    NamespaceSyncOutcome total = NamespaceSyncOutcome.zero;
    try {
      final manifestRead = await manifestStore.read(transport);

      // Pull first so per-namespace merge rules (best-progress override,
      // LWW) can fold remote state into ours before we push. Pushing first
      // would silently overwrite a remote completed session with a local
      // in-progress one when the in-progress row happens to be newer.
      // Puzzles must land before completions for FK satisfaction.
      for (final adapter in adapters) {
        total += await adapter.pull(transport);
      }
      for (final adapter in adapters) {
        total += await adapter.push(transport, deviceId);
      }

      // NOTE: the manifest is currently *write-once* — it's only (re)written
      // here on the fallback path (missing / corrupt / newer-schema). Routine
      // pushes do NOT yet update it, so once written it advertises only the
      // remote state captured at rebuild time. That's safe today because pull
      // is still a full namespace scan and never consults the manifest.
      //
      // WARNING for the next phase: do not drive incremental pull off this
      // manifest until pushes also fold their written entries back into it
      // (SyncManifest.withEntry) and persist local cursors. A reader trusting a
      // write-once manifest would skip another device's pushes → lost sync.
      if (manifestRead.requiresFallback) {
        final manifest = await manifestStore.rebuildFromRemote(
          transport: transport,
          adapters: adapters,
        );
        await manifestStore.write(transport, manifest);
      }
    } on SyncTransportException catch (e) {
      // Typed transport failure → a SyncError with the right retry semantics.
      // We do NOT rethrow: the error is already on the state stream, and the
      // fire-and-forget triggers (app-resume, post-solve) must not see an
      // uncaught exception. Callers read the live state for the outcome.
      _setState(SyncError(_messageForTransport(e), transient: e.isTransient));
      return SyncResult.zero;
    } on Object catch (e) {
      _setState(SyncError(e.toString(), transient: true));
      return SyncResult.zero;
    }

    final result = SyncResult(
      pushed: total.pushed,
      pulled: total.pulled,
      conflicts: total.conflicts,
      duration: DateTime.now().difference(start),
    );
    _lastSyncedAt = DateTime.now().toUtc();
    _setState(SyncIdle(lastSyncedAt: _lastSyncedAt));
    return result;
  }

  Future<void> dispose() async {
    await _stateController.close();
  }

  /// Reads or generates the stable per-install device id. Stored in
  /// `app_settings` under the `device_id` key (excluded from sync via
  /// [SettingsSyncAdapter.excludedKeys]).
  Future<String> _resolveDeviceId() async {
    final raw = await db.appSettingsDao.getValue('device_id');
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is String) return decoded;
    }
    final fresh = Uuid.v4();
    await db.appSettingsDao.setValue('device_id', jsonEncode(fresh));
    return fresh;
  }

  /// User-facing copy for a typed transport failure surfaced in the status UI.
  String _messageForTransport(SyncTransportException e) {
    switch (e.kind) {
      case SyncTransportErrorKind.locked:
        return 'Another device is syncing right now — will retry shortly.';
      case SyncTransportErrorKind.quotaExceeded:
        return 'Cloud storage is full. Free up space to keep syncing.';
      case SyncTransportErrorKind.permissionDenied:
        return "Crosscue can't access cloud storage — check its permissions.";
      case SyncTransportErrorKind.io:
        return 'Sync hit a storage error — will retry.';
    }
  }

  void _setState(SyncState next) {
    _state = next;
    _stateController.add(next);
  }
}
