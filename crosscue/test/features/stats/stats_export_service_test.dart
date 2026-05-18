// Tests for H3: StatsExportService domain interface + data implementation.
//
// Covered scenarios:
//   export – generateExportBytes produces valid UTF-8 JSON from imported records
//   import – importFromBytes parses and inserts new records, skips duplicates
//   import – rejects non-UTF-8 bytes, invalid JSON, and non-array payloads
//   import – skips records with missing required fields

import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/utils/uuid.dart';
import 'package:crosscue/features/stats/data/services/stats_export_service_impl.dart';
import 'package:crosscue/features/stats/domain/services/stats_export_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StatsExportServiceImpl service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = StatsExportServiceImpl(dao: db.statsDao);
  });

  tearDown(() => db.close());

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  group('generateExportBytes', () {
    test('returns empty JSON array when no completed records exist', () async {
      final result = await service.generateExportBytes();
      expect(result.isOk, isTrue);

      final decoded = jsonDecode(utf8.decode(result.value));
      expect(decoded, isA<List>());
      expect(decoded, isEmpty);
    });

    test('includes imported records in export JSON', () async {
      // Seed one imported record via the DAO.
      await db.statsDao.insertImportedRecord(
        (
          completionType: 'clean',
          elapsedMs: 90000,
          solvedDateLocal: '2025-01-01',
          solvedTimezone: 'America/Chicago',
          width: 5,
          height: 5,
          puzzleTitle: 'Test Puzzle',
        ),
      );

      final result = await service.generateExportBytes();
      expect(result.isOk, isTrue);

      final decoded = jsonDecode(utf8.decode(result.value)) as List;
      expect(decoded, hasLength(1));

      final first = decoded.first as Map<String, dynamic>;
      expect(first['completionType'], equals('clean'));
      expect(first['elapsedMs'], equals(90000));
      expect(first['solvedDateLocal'], equals('2025-01-01'));
      expect(first['solvedTimezone'], equals('America/Chicago'));
      expect(first['width'], equals(5));
      expect(first['height'], equals(5));
      expect(first['puzzleTitle'], equals('Test Puzzle'));
    });

    test('includes a local completion after its live session is reset',
        () async {
      final now = DateTime.utc(2025, 1, 2);
      await db.into(db.puzzlesTable).insert(
            PuzzlesTableCompanion.insert(
              id: 'puzzle-1',
              sourceId: 'local_import',
              format: 'ipuz',
              title: 'Reset Puzzle',
              width: 5,
              height: 5,
              checksum: 'checksum',
              canonicalJson: '{}',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.solveSessionsTable).insert(
            SolveSessionsTableCompanion.insert(
              puzzleId: 'puzzle-1',
              deviceId: 'device-1',
              status: const Value('in_progress'),
              startedAt: now,
              lastPlayedAt: now,
              elapsedMs: const Value(0),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.puzzleCompletionsTable).insert(
            PuzzleCompletionsTableCompanion.insert(
              puzzleId: 'puzzle-1',
              completionType: 'clean',
              completedAt: now,
              solvedDateLocal: '2025-01-02',
              solvedTimezone: const Value('America/New_York'),
              elapsedMs: 42000,
              clientUuid: Uuid.v4(),
            ),
          );

      final result = await service.generateExportBytes();
      expect(result.isOk, isTrue);

      final decoded = jsonDecode(utf8.decode(result.value)) as List;
      expect(decoded, hasLength(1));
      final first = decoded.single as Map<String, dynamic>;
      expect(first['puzzleTitle'], equals('Reset Puzzle'));
      expect(first['solvedDateLocal'], equals('2025-01-02'));
      expect(first['elapsedMs'], equals(42000));
    });

    test('output is valid pretty-printed UTF-8 JSON', () async {
      final result = await service.generateExportBytes();
      expect(result.isOk, isTrue);
      // Must decode without throwing.
      expect(() => utf8.decode(result.value), returnsNormally);
      expect(() => jsonDecode(utf8.decode(result.value)), returnsNormally);
    });
  });

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  group('importFromBytes – success path', () {
    test('inserts new records and returns count', () async {
      final payload = jsonEncode([
        {
          'completionType': 'clean',
          'elapsedMs': 60000,
          'solvedDateLocal': '2025-03-15',
          'solvedTimezone': 'America/New_York',
          'width': 5,
          'height': 5,
          'puzzleTitle': 'Saturday Mini',
        },
      ]);

      final result = await service
          .importFromBytes(Uint8List.fromList(utf8.encode(payload)));
      expect(result.isOk, isTrue);
      expect(result.value, equals(1));
    });

    test('skips duplicate records (same puzzleTitle + solvedDateLocal)',
        () async {
      final payload = jsonEncode([
        {
          'completionType': 'clean',
          'elapsedMs': 60000,
          'solvedDateLocal': '2025-03-15',
          'width': 5,
          'height': 5,
          'puzzleTitle': 'Saturday Mini',
        },
      ]);
      final bytes = Uint8List.fromList(utf8.encode(payload));

      final first = await service.importFromBytes(bytes);
      expect(first.isOk, isTrue);
      expect(first.value, equals(1));

      final second = await service.importFromBytes(bytes);
      expect(second.isOk, isTrue);
      expect(second.value, equals(0)); // duplicate skipped
    });

    test('imports multiple records, returns correct count', () async {
      final payload = jsonEncode([
        {
          'completionType': 'clean',
          'elapsedMs': 60000,
          'solvedDateLocal': '2025-03-15',
          'width': 5,
          'height': 5,
          'puzzleTitle': 'Puzzle A',
        },
        {
          'completionType': 'checked',
          'elapsedMs': 120000,
          'solvedDateLocal': '2025-03-16',
          'width': 5,
          'height': 5,
          'puzzleTitle': 'Puzzle B',
        },
      ]);

      final result = await service
          .importFromBytes(Uint8List.fromList(utf8.encode(payload)));
      expect(result.isOk, isTrue);
      expect(result.value, equals(2));
    });

    test('solvedTimezone is optional — record still imported when absent',
        () async {
      final payload = jsonEncode([
        {
          'completionType': 'clean',
          'elapsedMs': 45000,
          'solvedDateLocal': '2025-04-01',
          'width': 5,
          'height': 5,
          'puzzleTitle': 'No TZ Puzzle',
          // solvedTimezone intentionally omitted
        },
      ]);

      final result = await service
          .importFromBytes(Uint8List.fromList(utf8.encode(payload)));
      expect(result.isOk, isTrue);
      expect(result.value, equals(1));
    });
  });

  group('importFromBytes – error / skip cases', () {
    test('returns ExportFormatError for non-UTF-8 bytes', () async {
      // 0xFF 0xFE is a BOM that makes utf8.decode throw.
      final result =
          await service.importFromBytes(Uint8List.fromList([0xFF, 0xFE]));
      expect(result.isErr, isTrue);
      expect(result.error, isA<ExportFormatError>());
    });

    test('returns ExportFormatError for invalid JSON', () async {
      final result = await service
          .importFromBytes(Uint8List.fromList(utf8.encode('not json {')));
      expect(result.isErr, isTrue);
      expect(result.error, isA<ExportFormatError>());
    });

    test('returns ExportFormatError when root element is not a JSON array',
        () async {
      final result = await service.importFromBytes(
        Uint8List.fromList(utf8.encode('{"key":"value"}')),
      );
      expect(result.isErr, isTrue);
      expect(result.error, isA<ExportFormatError>());
    });

    test('skips records missing required fields, imports valid ones', () async {
      final payload = jsonEncode([
        {
          // Missing 'elapsedMs'
          'completionType': 'clean',
          'solvedDateLocal': '2025-05-01',
          'width': 5,
          'height': 5,
          'puzzleTitle': 'Incomplete Record',
        },
        {
          'completionType': 'clean',
          'elapsedMs': 30000,
          'solvedDateLocal': '2025-05-02',
          'width': 5,
          'height': 5,
          'puzzleTitle': 'Valid Record',
        },
      ]);

      final result = await service
          .importFromBytes(Uint8List.fromList(utf8.encode(payload)));
      expect(result.isOk, isTrue);
      expect(result.value, equals(1)); // only the valid record
    });

    test('skips records with empty required string fields', () async {
      final payload = jsonEncode([
        {
          'completionType': 'clean',
          'elapsedMs': 30000,
          'solvedDateLocal': '', // empty — invalid
          'width': 5,
          'height': 5,
          'puzzleTitle': 'Test',
        },
        {
          'completionType': 'clean',
          'elapsedMs': 30000,
          'solvedDateLocal': '2025-05-02',
          'width': 5,
          'height': 5,
          'puzzleTitle': '', // empty — invalid
        },
      ]);

      final result = await service
          .importFromBytes(Uint8List.fromList(utf8.encode(payload)));
      expect(result.isOk, isTrue);
      expect(result.value, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip
  // ---------------------------------------------------------------------------

  group('export → import round-trip', () {
    test('exported bytes can be re-imported without duplicates', () async {
      // Seed one record.
      await db.statsDao.insertImportedRecord(
        (
          completionType: 'clean',
          elapsedMs: 75000,
          solvedDateLocal: '2025-06-01',
          solvedTimezone: null,
          width: 5,
          height: 5,
          puzzleTitle: 'Round Trip Puzzle',
        ),
      );

      final exportResult = await service.generateExportBytes();
      expect(exportResult.isOk, isTrue);

      // Import into a fresh DB after closing the export DB. Keeping two Drift
      // database instances open in the same test triggers Drift's multiple
      // database warning, even when both use in-memory executors.
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = StatsExportServiceImpl(dao: db.statsDao);

      final importResult = await service.importFromBytes(exportResult.value);
      expect(importResult.isOk, isTrue);
      expect(importResult.value, equals(1));

      // Re-importing is idempotent.
      final reimportResult = await service.importFromBytes(exportResult.value);
      expect(reimportResult.isOk, isTrue);
      expect(reimportResult.value, equals(0));
    });
  });
}
