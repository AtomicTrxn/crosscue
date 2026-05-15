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

    test('creates puzzle_completions table', () async {
      final file = File('${tempDir.path}/v3.db');
      final rawDb = raw_sqlite.sqlite3.open(file.path);
      try {
        // Build a minimal v3 schema (sources + crosshare seed + imported stats).
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
        rawDb.execute('PRAGMA user_version = 3');
      } finally {
        rawDb.dispose();
      }

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());

      // Table exists and is queryable after onUpgrade(m, 3, 4).
      expect(await db.select(db.puzzleCompletionsTable).get(), isEmpty);
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
