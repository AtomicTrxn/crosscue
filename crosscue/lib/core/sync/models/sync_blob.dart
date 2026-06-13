import 'dart:convert';

/// Envelope wrapped around every namespace payload before it's written to
/// the transport. See `docs/architecture/sync-design.md` (Wire format).
class SyncBlob {
  const SyncBlob({
    required this.schemaVersion,
    required this.deviceId,
    required this.syncVersion,
    required this.updatedAt,
    required this.payload,
  });

  /// Current envelope schema. Bumped only when the envelope itself changes;
  /// payload schema changes live inside the namespace payloads.
  static const int currentSchemaVersion = 1;

  /// Envelope schema version. Readers ignore unknown fields and skip blobs
  /// whose schema is newer than they understand (forward compatibility).
  final int schemaVersion;

  /// Originating device id at write time.
  final String deviceId;

  /// Monotonically-increasing per-entity version. Used to decide whether a
  /// remote blob is newer than what we have locally.
  final int syncVersion;

  /// Wall-clock at write time (UTC).
  final DateTime updatedAt;

  /// Namespace-specific JSON payload.
  final Map<String, Object?> payload;

  String encode() => jsonEncode({
        'schemaVersion': schemaVersion,
        'deviceId': deviceId,
        'syncVersion': syncVersion,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'payload': payload,
      });

  /// When [bytes] is a structurally plausible envelope whose schema is newer
  /// than this build understands, returns that schema version; otherwise
  /// null. Distinguishes "written by a newer app version" — which triggers
  /// the ADR-0016 mixed-version guard (suspend pushes, prompt to update) —
  /// from malformed bytes, which stay a silent skip.
  static int? peekNewerSchemaVersion(String bytes) {
    final Object? json;
    try {
      json = jsonDecode(bytes);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is int && schemaVersion > currentSchemaVersion) {
      return schemaVersion;
    }
    return null;
  }

  /// Returns null if [bytes] cannot be decoded or the schema is newer than
  /// [currentSchemaVersion]. Callers should treat that as "skip this blob"
  /// (and use [peekNewerSchemaVersion] to tell the two cases apart).
  static SyncBlob? decode(String bytes) {
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

    final deviceId = json['deviceId'];
    final syncVersion = json['syncVersion'];
    final updatedAtStr = json['updatedAt'];
    final payload = json['payload'];
    if (deviceId is! String ||
        syncVersion is! int ||
        updatedAtStr is! String ||
        payload is! Map<String, Object?>) {
      return null;
    }

    final updatedAt = DateTime.tryParse(updatedAtStr);
    if (updatedAt == null) return null;

    return SyncBlob(
      schemaVersion: schemaVersion,
      deviceId: deviceId,
      syncVersion: syncVersion,
      updatedAt: updatedAt,
      payload: payload,
    );
  }
}
