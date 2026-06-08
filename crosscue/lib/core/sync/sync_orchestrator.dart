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
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/models/sync_result.dart';
import 'package:crosscue/core/sync/models/sync_state.dart';
import 'package:crosscue/core/sync/sync_manifest_store.dart';
import 'package:crosscue/core/sync/transport/no_op_sync_transport.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:crosscue/core/utils/uuid.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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
      // The remote is gone; our cursors describe state that no longer exists.
      // Drop them so a later re-enable rediscovers the remote from scratch.
      await db.remoteSyncCursorDao.clearAll();
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
      // A missing / corrupt / newer-schema manifest → full namespace scan and
      // rebuild. Otherwise diff the manifest against our cursors and read only
      // what changed.
      final fallback = manifestRead.requiresFallback;
      final manifest = manifestRead.manifest;

      // Pull first so per-namespace merge rules (best-progress override, LWW)
      // can fold remote state into ours before we push. Puzzles must land
      // before sessions/completions for FK satisfaction — adapter order does
      // that within this single pass.
      final seenByNs = <SyncNamespace, Map<String, SyncManifestEntry>>{};
      for (final adapter in adapters) {
        final onlyKeys =
            fallback ? null : await _changedKeys(adapter.namespace, manifest!);
        final result = await adapter.pull(transport, onlyKeys: onlyKeys);
        total += result.outcome;
        seenByNs[adapter.namespace] = result.seen;
        await _advanceCursors(adapter.namespace, result.caughtUp);
      }

      final writtenByNs = <SyncNamespace, Map<String, SyncManifestEntry>>{};
      for (final adapter in adapters) {
        final remoteIndex = fallback
            ? seenByNs[adapter.namespace]!
            : manifest!.entriesFor(adapter.namespace);
        final result = await adapter.push(
          transport,
          deviceId,
          remoteIndex: remoteIndex,
        );
        total += result.outcome;
        writtenByNs[adapter.namespace] = result.written;
        // Advance our own cursor for what we just uploaded so we don't re-pull
        // our own writes next pass.
        await _advanceCursors(adapter.namespace, result.written);
      }

      // Update the remote manifest *after* the blob writes, so it never
      // advertises data that wasn't uploaded. On fallback we rebuild it from
      // everything we saw + wrote; otherwise we fold our writes into the
      // manifest we read. A no-op incremental pass writes nothing.
      final anyWrites = writtenByNs.values.any((m) => m.isNotEmpty);
      if (fallback || anyWrites) {
        final next = _composeManifest(
          fallback: fallback,
          previous: manifest,
          seenByNs: seenByNs,
          writtenByNs: writtenByNs,
        );
        final bytes = await manifestStore.write(transport, next);
        _logManifestSize(next.entryCount, bytes);
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

  /// The remote keys in [manifest] for [namespace] whose entry differs from our
  /// local cursor (or that we have no cursor for) — i.e. what actually changed
  /// remotely since we last reconciled. Unchanged keys are skipped entirely, so
  /// a no-op pass reads nothing beyond the manifest.
  Future<List<String>> _changedKeys(
    SyncNamespace namespace,
    SyncManifest manifest,
  ) async {
    final cursors = await db.remoteSyncCursorDao.getNamespaceCursors(namespace);
    final cursorByKey = {for (final c in cursors) c.syncKey: c};
    final changed = <String>[];
    for (final entry in manifest.entriesFor(namespace).entries) {
      final cursor = cursorByKey[entry.key];
      // Compare on (syncVersion, deviceId) only — both reliably identify a
      // distinct remote write. `updatedAt` is derived and, because the cursor
      // store persists DateTime at second precision, can't be compared exactly
      // against the sub-second value in the manifest JSON.
      final isStale = cursor == null ||
          cursor.syncVersion != entry.value.syncVersion ||
          cursor.deviceId != entry.value.deviceId;
      if (isStale) changed.add(entry.key);
    }
    return changed;
  }

  /// Records [entries] as reconciled for [namespace] so future passes skip them.
  Future<void> _advanceCursors(
    SyncNamespace namespace,
    Map<String, SyncManifestEntry> entries,
  ) async {
    for (final entry in entries.entries) {
      await db.remoteSyncCursorDao.upsertCursor(
        namespace: namespace,
        syncKey: entry.key,
        metadata: entry.value,
      );
    }
  }

  /// Builds the manifest to write back. On [fallback] it's rebuilt from what we
  /// saw + wrote across all namespaces; otherwise it's [previous] with our
  /// freshly-written entries folded in.
  SyncManifest _composeManifest({
    required bool fallback,
    required SyncManifest? previous,
    required Map<SyncNamespace, Map<String, SyncManifestEntry>> seenByNs,
    required Map<SyncNamespace, Map<String, SyncManifestEntry>> writtenByNs,
  }) {
    final namespaces = <SyncNamespace, Map<String, SyncManifestEntry>>{
      for (final namespace in SyncNamespace.values)
        namespace: {
          ...(fallback
              ? (seenByNs[namespace] ?? const {})
              : previous!.entriesFor(namespace)),
          ...(writtenByNs[namespace] ?? const {}),
        },
    };
    return SyncManifest(
      schemaVersion: SyncManifest.currentSchemaVersion,
      updatedAt: DateTime.now().toUtc(),
      namespaces: namespaces,
    );
  }

  /// Surfaces manifest growth for beta observation (#207). The manifest is a
  /// single JSON blob read once per sync and rewritten on any write-pass, so
  /// its size is a Drive-cost signal. Crossing
  /// [SyncManifest.softEntryWarningThreshold] is the cue to shard it per
  /// namespace or compact it — this only logs; it changes no behavior.
  void _logManifestSize(int entryCount, int bytes) {
    if (entryCount > SyncManifest.softEntryWarningThreshold) {
      debugPrint(
        '[sync] manifest large: $entryCount entries, $bytes B — consider '
        'sharding per namespace or compacting (#207)',
      );
    } else {
      debugPrint('[sync] manifest: $entryCount entries, $bytes B');
    }
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
