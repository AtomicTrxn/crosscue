// Tests for AppDatabase schema and migration strategy (H7).
//
// Coverage:
//   – onCreate creates all expected tables (verified by insert/query)
//   – v1 → v2 migration creates imported_solve_stats table
//   – v2 → v3 migration seeds crosshare_daily_mini source row
//   – onUpgrade downgrade safety: StateError thrown for from > to
//   – clearAllUserData removes puzzles, stats, and settings

import 'dart:io';

import 'package:crosscue/core/database/app_database.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw_sqlite;

void main() {
  // ---------------------------------------------------------------------------
  // onCreate (fresh DB)
  // ---------------------------------------------------------------------------

  group('onCreate – fresh schema', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('puzzles table is queryable after onCreate', () async {
      expect(await db.select(db.puzzlesTable).get(), isEmpty);
    });

    test('solve_sessions table is queryable after onCreate', () async {
      expect(await db.select(db.solveSessionsTable).get(), isEmpty);
    });

    test('cell_progress table is queryable after onCreate', () async {
      expect(await db.select(db.cellProgressTable).get(), isEmpty);
    });

    test('app_settings table is queryable after onCreate', () async {
      expect(await db.select(db.appSettingsTable).get(), isEmpty);
    });

    test('imported_solve_stats table is queryable after onCreate', () async {
      expect(await db.select(db.importedSolveStatsTable).get(), isEmpty);
    });

    test('sources table is seeded with local_import row on first create',
        () async {
      final rows = await db.select(db.sourcesTable).get();
      expect(rows.any((r) => r.id == 'local_import'), isTrue);
    });

    test(
        'sources table is seeded with crosshare_daily_mini row on first create',
        () async {
      final rows = await db.select(db.sourcesTable).get();
      expect(rows.any((r) => r.id == 'crosshare_daily_mini'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // v1 → v2 migration
  // ---------------------------------------------------------------------------

  group('v1 → v2 migration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('drift_v1_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test(
        'creates imported_solve_stats table and it is queryable after migration',
        () async {
      final file = File('${tempDir.path}/v1.db');

      // Build a minimal v1 schema using raw sqlite3.
      // We only need the sources table so the seeding in onCreate won't be
      // re-triggered (version mismatch → onUpgrade, not onCreate).
      final rawDb = raw_sqlite.sqlite3.open(file.path);
      try {
        rawDb.execute('''
          CREATE TABLE sources (
            id TEXT NOT NULL PRIMARY KEY,
            display_name TEXT NOT NULL,
            type TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('PRAGMA user_version = 1');
      } finally {
        rawDb.dispose();
      }

      // Open with AppDatabase — should trigger onUpgrade(m, 1, 2)
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());

      // The migration should have created imported_solve_stats.
      final now = DateTime.now().toUtc();
      await db.into(db.importedSolveStatsTable).insert(
            ImportedSolveStatsTableCompanion.insert(
              completionType: 'clean',
              elapsedMs: 30000,
              solvedDateLocal: '2025-01-01',
              width: 5,
              height: 5,
              puzzleTitle: 'Migration Test Puzzle',
              importedAt: now,
            ),
          );

      final rows = await db.select(db.importedSolveStatsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.puzzleTitle, equals('Migration Test Puzzle'));
    });

    test('existing v1 data is preserved after migration', () async {
      final file = File('${tempDir.path}/v1_data.db');
      final rawDb = raw_sqlite.sqlite3.open(file.path);
      try {
        // Minimal v1 sources table — only columns that existed in v1.
        rawDb.execute('''
          CREATE TABLE sources (
            id TEXT NOT NULL PRIMARY KEY,
            display_name TEXT NOT NULL,
            type TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO sources (id, display_name, type, enabled, created_at, updated_at)
          VALUES ('local_import', 'Local Import', 'local', 1,
                  strftime('%s','now'), strftime('%s','now'))
        ''');
        rawDb.execute('PRAGMA user_version = 1');
      } finally {
        rawDb.dispose();
      }

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());

      // Use raw SQL to verify the pre-migration row survived.
      // (Drift's typed query would fail on missing v1→v2 schema columns.)
      final result = await db.customSelect(
        'SELECT COUNT(*) AS cnt FROM sources WHERE id = ?',
        variables: [const Variable<String>('local_import')],
      ).getSingle();
      expect(result.read<int>('cnt'), equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // v2 → v3 migration
  // ---------------------------------------------------------------------------

  group('v2 → v3 migration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('drift_v2_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('seeds crosshare_daily_mini source row', () async {
      final file = File('${tempDir.path}/v2.db');

      // Build a minimal v2 schema using raw sqlite3.
      final rawDb = raw_sqlite.sqlite3.open(file.path);
      try {
        rawDb.execute('''
          CREATE TABLE sources (
            id TEXT NOT NULL PRIMARY KEY,
            display_name TEXT NOT NULL,
            type TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO sources (id, display_name, type, enabled, created_at, updated_at)
          VALUES ('local_import', 'Local Import', 'local', 1,
                  strftime('%s','now'), strftime('%s','now'))
        ''');
        rawDb.execute('''
          CREATE TABLE imported_solve_stats (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            completion_type TEXT NOT NULL,
            elapsed_ms INTEGER NOT NULL,
            solved_date_local TEXT NOT NULL,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            puzzle_title TEXT NOT NULL,
            imported_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('PRAGMA user_version = 2');
      } finally {
        rawDb.dispose();
      }

      // Open with AppDatabase — should trigger onUpgrade(m, 2, 3).
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());

      final result = await db.customSelect(
        'SELECT COUNT(*) AS cnt FROM sources WHERE id = ?',
        variables: [const Variable<String>('crosshare_daily_mini')],
      ).getSingle();
      expect(result.read<int>('cnt'), equals(1));
    });

    test('local_import row is preserved during v2 → v3 migration', () async {
      final file = File('${tempDir.path}/v2_data.db');
      final rawDb = raw_sqlite.sqlite3.open(file.path);
      try {
        rawDb.execute('''
          CREATE TABLE sources (
            id TEXT NOT NULL PRIMARY KEY,
            display_name TEXT NOT NULL,
            type TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO sources (id, display_name, type, enabled, created_at, updated_at)
          VALUES ('local_import', 'Local Import', 'local', 1,
                  strftime('%s','now'), strftime('%s','now'))
        ''');
        rawDb.execute('''
          CREATE TABLE imported_solve_stats (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            completion_type TEXT NOT NULL,
            elapsed_ms INTEGER NOT NULL,
            solved_date_local TEXT NOT NULL,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            puzzle_title TEXT NOT NULL,
            imported_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('PRAGMA user_version = 2');
      } finally {
        rawDb.dispose();
      }

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());

      final result = await db.customSelect(
        'SELECT COUNT(*) AS cnt FROM sources WHERE id = ?',
        variables: [const Variable<String>('local_import')],
      ).getSingle();
      expect(result.read<int>('cnt'), equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // v3 → v4 migration
  // ---------------------------------------------------------------------------

  group('v3 → v4 migration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('drift_v3_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('creates puzzle_completions table and backfills completed sessions',
        () async {
      final file = File('${tempDir.path}/v3.db');
      final rawDb = raw_sqlite.sqlite3.open(file.path);
      try {
        // Build a minimal v3 schema with one completed session to migrate.
        rawDb.execute('''
          CREATE TABLE sources (
            id TEXT NOT NULL PRIMARY KEY,
            display_name TEXT NOT NULL,
            type TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          CREATE TABLE imported_solve_stats (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            completion_type TEXT NOT NULL,
            elapsed_ms INTEGER NOT NULL,
            solved_date_local TEXT NOT NULL,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            puzzle_title TEXT NOT NULL,
            imported_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO sources (id, display_name, type, enabled, created_at, updated_at)
          VALUES ('local_import', 'Local Import', 'local', 1, 1, 1)
        ''');
        rawDb.execute('''
          CREATE TABLE puzzles (
            id TEXT NOT NULL PRIMARY KEY,
            source_id TEXT NOT NULL,
            source_puzzle_id TEXT,
            format TEXT NOT NULL,
            title TEXT NOT NULL,
            author TEXT,
            editor TEXT,
            publisher TEXT,
            copyright TEXT,
            notes TEXT,
            publish_date INTEGER,
            difficulty TEXT,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            checksum TEXT NOT NULL,
            canonical_json TEXT NOT NULL,
            raw_payload TEXT,
            fetched_at INTEGER,
            expires_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO puzzles (
            id, source_id, format, title, width, height, checksum,
            canonical_json, created_at, updated_at
          )
          VALUES ('puzzle-1', 'local_import', 'ipuz', 'Migrated Puzzle',
                  5, 5, 'checksum', '{}', 1, 1)
        ''');
        rawDb.execute('''
          CREATE TABLE solve_sessions (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            puzzle_id TEXT NOT NULL,
            device_id TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'not_started',
            completion_type TEXT,
            started_at INTEGER NOT NULL,
            last_played_at INTEGER NOT NULL,
            completed_at INTEGER,
            solved_date_local TEXT,
            solved_timezone TEXT,
            elapsed_ms INTEGER NOT NULL DEFAULT 0,
            is_paused INTEGER NOT NULL DEFAULT 0,
            paused_at INTEGER,
            total_paused_ms INTEGER NOT NULL DEFAULT 0,
            mistake_count INTEGER NOT NULL DEFAULT 0,
            check_count INTEGER NOT NULL DEFAULT 0,
            reveal_count INTEGER NOT NULL DEFAULT 0,
            used_check INTEGER NOT NULL DEFAULT 0,
            used_reveal INTEGER NOT NULL DEFAULT 0,
            clean_solve_eligible INTEGER NOT NULL DEFAULT 1,
            focus_row INTEGER NOT NULL DEFAULT 0,
            focus_col INTEGER NOT NULL DEFAULT 0,
            direction TEXT NOT NULL DEFAULT 'across',
            is_synced INTEGER NOT NULL DEFAULT 0,
            sync_version INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO solve_sessions (
            puzzle_id, device_id, status, completion_type, started_at,
            last_played_at, completed_at, solved_date_local, solved_timezone,
            elapsed_ms, check_count, reveal_count, created_at, updated_at
          )
          VALUES (
            'puzzle-1', 'device-1', 'completed', 'checked', 10, 20, 30,
            '2025-01-02', 'America/New_York', 45000, 2, 1, 10, 30
          )
        ''');
        rawDb.execute('PRAGMA user_version = 3');
      } finally {
        rawDb.dispose();
      }

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());

      final rows = await db.select(db.puzzleCompletionsTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.puzzleId, equals('puzzle-1'));
      expect(rows.single.completionType, equals('checked'));
      expect(rows.single.solvedDateLocal, equals('2025-01-02'));
      expect(rows.single.solvedTimezone, equals('America/New_York'));
      expect(rows.single.elapsedMs, equals(45000));
      expect(rows.single.checkCount, equals(2));
      expect(rows.single.revealCount, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // v4 → v5 migration
  // ---------------------------------------------------------------------------

  group('v4 → v5 migration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('drift_v4_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test(
        'adds sync-readiness columns and backfills client_uuid for existing '
        'completions', () async {
      final file = File('${tempDir.path}/v4.db');
      final rawDb = raw_sqlite.sqlite3.open(file.path);
      try {
        // Build a minimal v4 schema with two existing completion rows.
        rawDb.execute('''
          CREATE TABLE sources (
            id TEXT NOT NULL PRIMARY KEY,
            display_name TEXT NOT NULL,
            type TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO sources (id, display_name, type, enabled, created_at, updated_at)
          VALUES ('local_import', 'Local Import', 'local', 1, 1, 1)
        ''');
        rawDb.execute('''
          CREATE TABLE puzzles (
            id TEXT NOT NULL PRIMARY KEY,
            source_id TEXT NOT NULL,
            source_puzzle_id TEXT,
            format TEXT NOT NULL,
            title TEXT NOT NULL,
            author TEXT,
            editor TEXT,
            publisher TEXT,
            copyright TEXT,
            notes TEXT,
            publish_date INTEGER,
            difficulty TEXT,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            checksum TEXT NOT NULL,
            canonical_json TEXT NOT NULL,
            raw_payload TEXT,
            fetched_at INTEGER,
            expires_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO puzzles (id, source_id, format, title, width, height,
                               checksum, canonical_json, created_at, updated_at)
          VALUES ('puzzle-1', 'local_import', 'ipuz', 'P1', 5, 5,
                  'cksum', '{}', 1, 1)
        ''');
        rawDb.execute('''
          CREATE TABLE app_settings (
            key TEXT NOT NULL PRIMARY KEY,
            value_json TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO app_settings (key, value_json, updated_at)
          VALUES ('theme_mode', '"light"', 1)
        ''');
        rawDb.execute('''
          CREATE TABLE puzzle_completions (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            puzzle_id TEXT NOT NULL,
            completion_type TEXT NOT NULL,
            completed_at INTEGER NOT NULL,
            solved_date_local TEXT NOT NULL,
            solved_timezone TEXT,
            elapsed_ms INTEGER NOT NULL,
            check_count INTEGER NOT NULL DEFAULT 0,
            reveal_count INTEGER NOT NULL DEFAULT 0
          )
        ''');
        rawDb.execute('''
          INSERT INTO puzzle_completions
            (puzzle_id, completion_type, completed_at, solved_date_local,
             elapsed_ms)
          VALUES ('puzzle-1', 'clean', 1000, '2026-01-01', 60000),
                 ('puzzle-1', 'checked', 2000, '2026-01-02', 45000)
        ''');
        rawDb.execute('PRAGMA user_version = 4');
      } finally {
        rawDb.dispose();
      }

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());

      // New sync-readiness columns are present and queryable.
      final puzzles = await db.select(db.puzzlesTable).get();
      expect(puzzles, hasLength(1));
      expect(puzzles.single.isSynced, isFalse);
      expect(puzzles.single.syncVersion, equals(0));

      // app_settings.sync_version defaults to 0.
      final settings = await db.select(db.appSettingsTable).get();
      expect(settings, hasLength(1));
      expect(settings.single.syncVersion, equals(0));

      // Existing completion rows are backfilled with unique UUIDs.
      final completions = await db.select(db.puzzleCompletionsTable).get();
      expect(completions, hasLength(2));
      final uuids = completions.map((c) => c.clientUuid).toSet();
      expect(uuids, hasLength(2));
      for (final uuid in uuids) {
        // UUID v4 canonical form: 8-4-4-4-12 lowercase hex.
        expect(
          uuid,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
              r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
      }
      expect(completions.map((c) => c.deviceId), everyElement(equals('local')));

      // Unique index on client_uuid is in place.
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND tbl_name = 'puzzle_completions'",
          )
          .get();
      expect(
        indexes.map((r) => r.read<String>('name')),
        contains('idx_puzzle_completions_client_uuid'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // v5 → v6 migration
  // ---------------------------------------------------------------------------

  group('v5 → v6 migration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('drift_v5_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test(
        'adds fillable_cell_count to puzzles and backfills from '
        'canonical_json', () async {
      final file = File('${tempDir.path}/v5.db');
      final rawDb = raw_sqlite.sqlite3.open(file.path);
      try {
        // Minimal v5 schema for puzzles + a sources parent so the
        // foreign key is satisfied. Two puzzle rows with hand-written
        // canonical_json blobs so we can predict the backfilled count.
        rawDb.execute('''
          CREATE TABLE sources (
            id TEXT NOT NULL PRIMARY KEY,
            display_name TEXT NOT NULL,
            type TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          INSERT INTO sources (id, display_name, type, enabled, created_at, updated_at)
          VALUES ('local_import', 'Local Import', 'local', 1, 1, 1)
        ''');
        rawDb.execute('''
          CREATE TABLE puzzles (
            id TEXT NOT NULL PRIMARY KEY,
            source_id TEXT NOT NULL,
            source_puzzle_id TEXT,
            format TEXT NOT NULL,
            title TEXT NOT NULL,
            author TEXT,
            editor TEXT,
            publisher TEXT,
            copyright TEXT,
            notes TEXT,
            publish_date INTEGER,
            difficulty TEXT,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            checksum TEXT NOT NULL,
            canonical_json TEXT NOT NULL,
            raw_payload TEXT,
            fetched_at INTEGER,
            expires_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0,
            sync_version INTEGER NOT NULL DEFAULT 0
          )
        ''');
        // 2×2 grid with one black cell → 3 fillable.
        const grid2x2 = '''
          {"width":2,"height":2,"cells":[
            [{"black":false,"solution":"A"},{"black":true,"solution":""}],
            [{"black":false,"solution":"B"},{"black":false,"solution":"C"}]
          ]}
        ''';
        // 3×1 grid, no black cells → 3 fillable.
        const grid3x1 = '''
          {"width":3,"height":1,"cells":[
            [{"black":false,"solution":"D"},
             {"black":false,"solution":"E"},
             {"black":false,"solution":"F"}]
          ]}
        ''';
        rawDb.execute(
          'INSERT INTO puzzles (id, source_id, format, title, width, height, '
          'checksum, canonical_json, created_at, updated_at) VALUES '
          "('p-2x2', 'local_import', 'ipuz', '2x2', 2, 2, 'cksum1', "
          "?, 1, 1), "
          "('p-3x1', 'local_import', 'ipuz', '3x1', 3, 1, 'cksum2', "
          "?, 1, 1), "
          // Intentionally malformed canonical_json — backfill should
          // leave its fillable_cell_count at the default 0, not abort
          // the migration.
          "('p-bad', 'local_import', 'ipuz', 'bad', 1, 1, 'cksum3', "
          "'not-json', 1, 1)",
          <Object?>[grid2x2, grid3x1],
        );
        rawDb.execute('PRAGMA user_version = 5');
      } finally {
        rawDb.dispose();
      }

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());

      final puzzles = await db.select(db.puzzlesTable).get();
      expect(puzzles, hasLength(3));
      final byId = {for (final p in puzzles) p.id: p};
      expect(byId['p-2x2']!.fillableCellCount, equals(3));
      expect(byId['p-3x1']!.fillableCellCount, equals(3));
      expect(
        byId['p-bad']!.fillableCellCount,
        equals(0),
        reason: 'malformed canonical_json must fall through to default(0), '
            'not abort the migration',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // clearAllUserData
  // ---------------------------------------------------------------------------

  group('clearAllUserData', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('removes app_settings rows', () async {
      await db.appSettingsDao.setValue('test_key', 'test_value');
      expect(await db.select(db.appSettingsTable).get(), isNotEmpty);

      await db.clearAllUserData();
      expect(await db.select(db.appSettingsTable).get(), isEmpty);
    });

    test('removes imported_solve_stats rows', () async {
      final now = DateTime.now().toUtc();
      await db.into(db.importedSolveStatsTable).insert(
            ImportedSolveStatsTableCompanion.insert(
              completionType: 'clean',
              elapsedMs: 60000,
              solvedDateLocal: '2025-01-01',
              width: 5,
              height: 5,
              puzzleTitle: 'To Be Deleted',
              importedAt: now,
            ),
          );
      expect(await db.select(db.importedSolveStatsTable).get(), isNotEmpty);

      await db.clearAllUserData();
      expect(await db.select(db.importedSolveStatsTable).get(), isEmpty);
    });

    test('preserves sources seed row after clear', () async {
      await db.clearAllUserData();
      final sources = await db.select(db.sourcesTable).get();
      // sources is not cleared — only puzzles, stats, settings
      // (The sources table is seeded on onCreate and not cleared by design)
      expect(sources, isNotEmpty);
    });
  });
}
