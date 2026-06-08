import 'dart:convert';

import 'package:crosscue/core/sync/models/sync_namespace.dart';

/// Small remote index blob listing per-namespace key metadata. Lets a sync pass
/// compute which remote blobs changed without listing+reading every blob. See
/// issue #189.
///
/// The manifest is an **optimization index, not the source of truth**: every
/// blob it points at is still decoded and run through the adapter merge rules.
/// Only a writer (a device that pushes / rebuilds) updates it; readers compare
/// it against their local cursors and never mutate it. A missing / corrupt /
/// newer-schema manifest makes the orchestrator fall back to a full scan.
class SyncManifest {
  const SyncManifest({
    required this.schemaVersion,
    required this.updatedAt,
    required this.namespaces,
  });

  /// An empty, current-schema manifest with every namespace present but bare.
  /// Used as the seed before folding in entries during a rebuild/first write.
  factory SyncManifest.empty({DateTime? now}) => SyncManifest(
        schemaVersion: currentSchemaVersion,
        updatedAt: now?.toUtc() ?? DateTime.now().toUtc(),
        namespaces: {
          for (final namespace in SyncNamespace.values)
            namespace: <String, SyncManifestEntry>{},
        },
      );

  static const int currentSchemaVersion = 1;

  /// Transport key the manifest blob is stored under. Distinct from every
  /// [SyncNamespace.prefix] so namespace `list()` calls never return it.
  static const String manifestKey = 'manifest/v1.json';

  /// Soft threshold for [entryCount] above which the single-blob manifest is
  /// worth sharding per namespace (e.g. `manifest/puzzles.json`) or compacting.
  ///
  /// The manifest is one JSON document read once per sync and rewritten on
  /// every write-pass, so a very large blob erodes the incremental-sync win for
  /// big libraries. ~2000 entries (≈ a few hundred KB of JSON) is a
  /// conservative point to revisit — purely a watch line; crossing it changes
  /// no behavior. The orchestrator logs when it's exceeded (issue #207).
  static const int softEntryWarningThreshold = 2000;

  final int schemaVersion;
  final DateTime updatedAt;
  final Map<SyncNamespace, Map<String, SyncManifestEntry>> namespaces;

  /// Total entries across all namespaces — one per remote blob. The manifest's
  /// unbounded-growth signal; see [softEntryWarningThreshold] (#207).
  int get entryCount =>
      namespaces.values.fold(0, (sum, entries) => sum + entries.length);

  /// All entries for [namespace], keyed by sync key. Empty map when absent.
  Map<String, SyncManifestEntry> entriesFor(SyncNamespace namespace) =>
      namespaces[namespace] ?? const <String, SyncManifestEntry>{};

  /// The entry for ([namespace], [key]), or null if the manifest doesn't list
  /// it.
  SyncManifestEntry? entryFor(SyncNamespace namespace, String key) =>
      namespaces[namespace]?[key];

  /// Returns a copy with [entry] set for ([namespace], [key]) and a refreshed
  /// [updatedAt]. The receiver is left unchanged — used to fold successful
  /// pushes into the manifest before it's written back.
  SyncManifest withEntry(
    SyncNamespace namespace,
    String key,
    SyncManifestEntry entry, {
    DateTime? now,
  }) {
    final next = <SyncNamespace, Map<String, SyncManifestEntry>>{
      for (final e in namespaces.entries) e.key: {...e.value},
    };
    (next[namespace] ??= <String, SyncManifestEntry>{})[key] = entry;
    return SyncManifest(
      schemaVersion: currentSchemaVersion,
      updatedAt: now?.toUtc() ?? DateTime.now().toUtc(),
      namespaces: next,
    );
  }

  String encode() => jsonEncode({
        'schemaVersion': schemaVersion,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'namespaces': {
          for (final MapEntry(key: namespace, value: entries)
              in namespaces.entries)
            namespace.name: {
              for (final MapEntry(key: syncKey, value: metadata)
                  in entries.entries)
                syncKey: metadata.toJson(),
            },
        },
      });

  static SyncManifest? decode(String bytes) {
    final Object? json;
    try {
      json = jsonDecode(bytes);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;

    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int || schemaVersion > currentSchemaVersion) {
      return null;
    }

    final updatedAtValue = json['updatedAt'];
    final namespacesValue = json['namespaces'];
    if (updatedAtValue is! String || namespacesValue is! Map<String, Object?>) {
      return null;
    }
    final updatedAt = DateTime.tryParse(updatedAtValue);
    if (updatedAt == null) return null;

    final namespaces = <SyncNamespace, Map<String, SyncManifestEntry>>{};
    for (final namespace in SyncNamespace.values) {
      final rawEntries = namespacesValue[namespace.name];
      if (rawEntries == null) {
        namespaces[namespace] = <String, SyncManifestEntry>{};
        continue;
      }
      if (rawEntries is! Map<String, Object?>) return null;

      final entries = <String, SyncManifestEntry>{};
      for (final MapEntry(key: syncKey, value: rawEntry)
          in rawEntries.entries) {
        if (rawEntry is! Map<String, Object?>) return null;
        final entry = SyncManifestEntry.fromJson(rawEntry);
        if (entry == null) return null;
        entries[syncKey] = entry;
      }
      namespaces[namespace] = entries;
    }

    return SyncManifest(
      schemaVersion: schemaVersion,
      updatedAt: updatedAt,
      namespaces: namespaces,
    );
  }
}

/// Per-key metadata recorded in the manifest: just enough to decide whether a
/// remote blob changed since we last reconciled it. Never authoritative for
/// conflict resolution — the decoded `SyncBlob` is.
class SyncManifestEntry {
  const SyncManifestEntry({
    required this.syncVersion,
    required this.updatedAt,
    required this.deviceId,
  });

  final int syncVersion;
  final DateTime updatedAt;
  final String deviceId;

  Map<String, Object?> toJson() => {
        'syncVersion': syncVersion,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deviceId': deviceId,
      };

  static SyncManifestEntry? fromJson(Map<String, Object?> json) {
    final syncVersion = json['syncVersion'];
    final updatedAtValue = json['updatedAt'];
    final deviceId = json['deviceId'];
    if (syncVersion is! int ||
        updatedAtValue is! String ||
        deviceId is! String) {
      return null;
    }
    final updatedAt = DateTime.tryParse(updatedAtValue);
    if (updatedAt == null) return null;

    return SyncManifestEntry(
      syncVersion: syncVersion,
      updatedAt: updatedAt,
      deviceId: deviceId,
    );
  }
}
