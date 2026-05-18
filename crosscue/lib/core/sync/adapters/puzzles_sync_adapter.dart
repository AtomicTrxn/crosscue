import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/adapters/namespace_sync_adapter.dart';
import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:drift/drift.dart';

/// Puzzles are content-addressable (id = `local:<sha256-prefix>`), so the
/// merge rule is set union — identical-id rows are byte-identical, and
/// different-id rows can't collide. No conflicts are possible.
class PuzzlesSyncAdapter extends NamespaceSyncAdapter {
  PuzzlesSyncAdapter(this.db);

  final AppDatabase db;

  @override
  SyncNamespace get namespace => SyncNamespace.puzzles;

  @override
  Future<NamespaceSyncOutcome> push(
    SyncTransport transport,
    String deviceId,
  ) async {
    final localRows = await (db.select(db.puzzlesTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
    if (localRows.isEmpty) return NamespaceSyncOutcome.zero;

    final remoteKeys = (await transport.list(namespace.prefix)).toSet();
    var pushed = 0;
    for (final row in localRows) {
      final key = keyFor(row.id);
      if (!remoteKeys.contains(key)) {
        final blob = SyncBlob(
          schemaVersion: SyncBlob.currentSchemaVersion,
          deviceId: deviceId,
          syncVersion: row.syncVersion + 1,
          updatedAt: DateTime.now().toUtc(),
          payload: _encodeRow(row),
        );
        await transport.write(key, blob.encode());
        pushed++;
      }
      // Mark synced regardless: either we just uploaded, or it was already
      // there (e.g. uploaded from another device).
      await (db.update(db.puzzlesTable)..where((t) => t.id.equals(row.id)))
          .write(
        PuzzlesTableCompanion(
          isSynced: const Value(true),
          syncVersion: Value(row.syncVersion + 1),
        ),
      );
    }
    return NamespaceSyncOutcome(pushed: pushed);
  }

  @override
  Future<NamespaceSyncOutcome> pull(SyncTransport transport) async {
    final remoteKeys = await transport.list(namespace.prefix);
    if (remoteKeys.isEmpty) return NamespaceSyncOutcome.zero;

    final localIds = (await (db.selectOnly(db.puzzlesTable)
              ..addColumns([db.puzzlesTable.id]))
            .map((r) => r.read(db.puzzlesTable.id))
            .get())
        .whereType<String>()
        .toSet();

    var pulled = 0;
    for (final key in remoteKeys) {
      final id = idFromKey(key);
      if (id == null || localIds.contains(id)) continue;

      final bytes = await transport.read(key);
      if (bytes == null) continue;
      final blob = SyncBlob.decode(bytes);
      if (blob == null) continue;

      final companion = _decodeRow(id, blob);
      if (companion == null) continue;
      await db.into(db.puzzlesTable).insert(companion);
      pulled++;
    }
    return NamespaceSyncOutcome(pulled: pulled);
  }

  Map<String, Object?> _encodeRow(PuzzleRow r) => <String, Object?>{
        'id': r.id,
        'sourceId': r.sourceId,
        'sourcePuzzleId': r.sourcePuzzleId,
        'format': r.format,
        'title': r.title,
        'author': r.author,
        'editor': r.editor,
        'publisher': r.publisher,
        'copyright': r.copyright,
        'notes': r.notes,
        'publishDate': r.publishDate?.toUtc().toIso8601String(),
        'difficulty': r.difficulty,
        'width': r.width,
        'height': r.height,
        'checksum': r.checksum,
        'canonicalJson': r.canonicalJson,
        'fetchedAt': r.fetchedAt?.toUtc().toIso8601String(),
        'expiresAt': r.expiresAt?.toUtc().toIso8601String(),
        'createdAt': r.createdAt.toUtc().toIso8601String(),
      };

  PuzzlesTableCompanion? _decodeRow(String id, SyncBlob blob) {
    final p = blob.payload;
    final sourceId = p['sourceId'];
    final format = p['format'];
    final title = p['title'];
    final width = p['width'];
    final height = p['height'];
    final checksum = p['checksum'];
    final canonicalJson = p['canonicalJson'];
    final createdAtStr = p['createdAt'];

    if (sourceId is! String ||
        format is! String ||
        title is! String ||
        width is! int ||
        height is! int ||
        checksum is! String ||
        canonicalJson is! String ||
        createdAtStr is! String) {
      return null;
    }

    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return null;

    return PuzzlesTableCompanion.insert(
      id: id,
      sourceId: sourceId,
      sourcePuzzleId: Value(p['sourcePuzzleId'] as String?),
      format: format,
      title: title,
      author: Value(p['author'] as String?),
      editor: Value(p['editor'] as String?),
      publisher: Value(p['publisher'] as String?),
      copyright: Value(p['copyright'] as String?),
      notes: Value(p['notes'] as String?),
      publishDate: Value(_parseDate(p['publishDate'])),
      difficulty: Value(p['difficulty'] as String?),
      width: width,
      height: height,
      checksum: checksum,
      canonicalJson: canonicalJson,
      fetchedAt: Value(_parseDate(p['fetchedAt'])),
      expiresAt: Value(_parseDate(p['expiresAt'])),
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      isSynced: const Value(true),
      syncVersion: Value(blob.syncVersion),
    );
  }

  DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
