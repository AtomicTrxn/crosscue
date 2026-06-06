import 'dart:convert';

import 'package:crosscue/core/sync/models/sync_namespace.dart';

class SyncManifest {
  const SyncManifest({
    required this.schemaVersion,
    required this.updatedAt,
    required this.namespaces,
  });

  static const int currentSchemaVersion = 1;
  static const String key = 'manifest/v1.json';

  final int schemaVersion;
  final DateTime updatedAt;
  final Map<SyncNamespace, Map<String, SyncManifestEntry>> namespaces;

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
