import 'dart:convert';
import 'dart:io';

import 'package:crosscue/core/database/tables/app_settings_table.dart';
import 'package:crosscue/core/database/tables/cell_progress_table.dart';
import 'package:crosscue/core/database/tables/clues_table.dart';
import 'package:crosscue/core/database/tables/imported_solve_stats_table.dart';
import 'package:crosscue/core/database/tables/puzzle_completions_table.dart';
import 'package:crosscue/core/database/tables/puzzles_table.dart';
import 'package:crosscue/core/database/tables/solve_sessions_table.dart';
import 'package:crosscue/core/database/tables/sources_table.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/utils/uuid.dart';
import 'package:crosscue/features/import/data/daos/puzzle_dao.dart';
import 'package:crosscue/features/settings/data/daos/app_settings_dao.dart';
import 'package:crosscue/features/solve/data/daos/puzzle_completion_dao.dart';
import 'package:crosscue/features/solve/data/daos/solve_session_dao.dart';
import 'package:crosscue/features/stats/data/daos/stats_dao.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SourcesTable,
    PuzzlesTable,
    CluesTable,
    SolveSessionsTable,
    CellProgressTable,
    AppSettingsTable,
    ImportedSolveStatsTable,
    PuzzleCompletionsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Expose for testing — accepts an in-memory executor.
  AppDatabase.forTesting(super.executor);

  /// DAO accessors
  PuzzleDao get puzzleDao => PuzzleDao(this);
  SolveSessionDao get solveSessionDao => SolveSessionDao(this);
  AppSettingsDao get appSettingsDao => AppSettingsDao(this);
  StatsDao get statsDao => StatsDao(this);
  PuzzleCompletionDao get puzzleCompletionDao => PuzzleCompletionDao(this);

  @override
  int get schemaVersion => 6;

  /// Migration strategy.
  ///
  /// ## Adding a new migration
  /// 1. Increment [schemaVersion].
  /// 2. Add a branch in [onUpgrade]: `if (from < N && to >= N) { ... }`
  /// 3. Add a test in `test/core/database/app_database_test.dart`.
  /// 4. Export a schema snapshot: `dart run drift_dev schema dump
  ///    lib/core/database/app_database.dart drift_schemas/`
  ///
  /// ## Version history
  /// v1 → v2: added `imported_solve_stats` table.
  /// v2 → v3: seeded `crosshare_daily_mini` source row (foreign-key fix).
  /// v3 → v4: added `puzzle_completions` table — immutable per-completion
  ///          history used by streak/leaderboard features so that the live
  ///          `solve_sessions` row can be cleared by "Reset puzzle" without
  ///          losing the record of the original solve.
  /// v4 → v5: sync-readiness columns on `puzzles`, `puzzle_completions`,
  ///          and `app_settings`. See `docs/architecture/sync-design.md`.
  /// v5 → v6: `puzzles.fillable_cell_count` — denormalized cell-shape data
  ///          backfilled from `canonical_json` on upgrade. Unblocks the
  ///          archive-list completion fraction without a full grid decode.
  ///          See issue #122.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedBuiltInSources();
        },
        onUpgrade: (m, from, to) async {
          // Safety: schema downgrades are not supported and indicate a bug.
          if (from > to) {
            throw StateError(
              'Schema downgrade not supported: from=$from, to=$to. '
              'The installed app has a newer DB schema than this build.',
            );
          }

          if (from < 2) {
            // v1 → v2: add the imported_solve_stats table.
            await m.createTable(importedSolveStatsTable);
          }

          if (from < 3) {
            // v2 → v3: seed the crosshare_daily_mini source so that puzzles
            // downloaded via the Crosshare downloader satisfy the foreign-key
            // constraint on puzzles.source_id.
            await _seedCrosshareSource();
          }

          if (from < 4) {
            // v3 → v4: add puzzle_completions table (immutable history).
            //
            // Uses raw CREATE TABLE pinned to the v4 schema rather than
            // `m.createTable(puzzleCompletionsTable)` so this branch stays
            // stable as the ORM definition grows. v4 → v5 adds the
            // sync-readiness columns on top.
            await customStatement('''
              CREATE TABLE puzzle_completions (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                puzzle_id TEXT NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
                completion_type TEXT NOT NULL,
                completed_at INTEGER NOT NULL,
                solved_date_local TEXT NOT NULL,
                solved_timezone TEXT,
                elapsed_ms INTEGER NOT NULL,
                check_count INTEGER NOT NULL DEFAULT 0,
                reveal_count INTEGER NOT NULL DEFAULT 0
              )
            ''');
            final solveSessionsTableExists = await customSelect(
              '''
                SELECT COUNT(*) AS cnt
                FROM sqlite_master
                WHERE type = 'table' AND name = 'solve_sessions'
              ''',
            ).getSingle();
            if (solveSessionsTableExists.read<int>('cnt') > 0) {
              await customStatement('''
              INSERT INTO puzzle_completions (
                puzzle_id,
                completion_type,
                completed_at,
                solved_date_local,
                solved_timezone,
                elapsed_ms,
                check_count,
                reveal_count
              )
              SELECT
                puzzle_id,
                completion_type,
                COALESCE(completed_at, updated_at, last_played_at, created_at),
                solved_date_local,
                solved_timezone,
                elapsed_ms,
                check_count,
                reveal_count
              FROM solve_sessions
              WHERE completion_type IS NOT NULL
                AND solved_date_local IS NOT NULL
            ''');
            }
          }

          if (from < 5) {
            // v4 → v5: sync-readiness columns. Additive only — no data loss.
            // `client_uuid` is NOT NULL on the schema; we add it with a
            // temporary default of '' so existing rows survive the ALTER,
            // then backfill UUIDs in Dart, then promote the column to
            // UNIQUE via an index. See `docs/architecture/sync-design.md`.
            //
            // Each ALTER is guarded by a table-existence check so that
            // historical minimal-schema tests (which omit some tables) still
            // pass — mirrors the v3 → v4 guard around `solve_sessions`.
            Future<bool> tableExists(String name) async {
              final row = await customSelect(
                'SELECT COUNT(*) AS cnt FROM sqlite_master '
                "WHERE type = 'table' AND name = ?",
                variables: [Variable<String>(name)],
              ).getSingle();
              return row.read<int>('cnt') > 0;
            }

            if (await tableExists('puzzles')) {
              await customStatement(
                'ALTER TABLE puzzles ADD COLUMN is_synced INTEGER '
                'NOT NULL DEFAULT 0',
              );
              await customStatement(
                'ALTER TABLE puzzles ADD COLUMN sync_version INTEGER '
                'NOT NULL DEFAULT 0',
              );
            }

            if (await tableExists('puzzle_completions')) {
              await customStatement(
                "ALTER TABLE puzzle_completions ADD COLUMN client_uuid TEXT "
                "NOT NULL DEFAULT ''",
              );
              await customStatement(
                "ALTER TABLE puzzle_completions ADD COLUMN device_id TEXT "
                "NOT NULL DEFAULT 'local'",
              );

              final rows = await customSelect(
                'SELECT id FROM puzzle_completions',
              ).get();
              for (final row in rows) {
                await customStatement(
                  'UPDATE puzzle_completions SET client_uuid = ? WHERE id = ?',
                  <Object?>[Uuid.v4(), row.read<int>('id')],
                );
              }

              await customStatement(
                'CREATE UNIQUE INDEX IF NOT EXISTS '
                'idx_puzzle_completions_client_uuid '
                'ON puzzle_completions(client_uuid)',
              );
            }

            if (await tableExists('app_settings')) {
              await customStatement(
                'ALTER TABLE app_settings ADD COLUMN sync_version INTEGER '
                'NOT NULL DEFAULT 0',
              );
            }
          }

          if (from < 6) {
            // v5 → v6: denormalize `fillable_cell_count` onto puzzles.
            //
            // Adds the column with a sentinel default of 0, then walks
            // every row and parses `canonical_json` to compute the real
            // count. The default is intentionally 0 (not NULL) so that
            // any row we fail to parse — or any future puzzle inserted
            // before the upgrade completes — still satisfies the NOT NULL
            // contract. `getAllMetadata` callers should treat 0 as
            // "unknown" rather than "no fillable cells".
            //
            // Guarded by the same tableExists pattern as v5 so the
            // historical minimal-schema tests in this file still pass.
            Future<bool> tableExists(String name) async {
              final row = await customSelect(
                'SELECT COUNT(*) AS cnt FROM sqlite_master '
                "WHERE type = 'table' AND name = ?",
                variables: [Variable<String>(name)],
              ).getSingle();
              return row.read<int>('cnt') > 0;
            }

            if (await tableExists('puzzles')) {
              await customStatement(
                'ALTER TABLE puzzles ADD COLUMN fillable_cell_count INTEGER '
                'NOT NULL DEFAULT 0',
              );

              final rows = await customSelect(
                'SELECT id, canonical_json FROM puzzles',
              ).get();
              for (final row in rows) {
                final count = _fillableCellCountFromCanonicalJson(
                  row.read<String>('canonical_json'),
                );
                if (count == null) {
                  continue; // Leave default (0) on parse error.
                }
                await customStatement(
                  'UPDATE puzzles SET fillable_cell_count = ? WHERE id = ?',
                  <Object?>[count, row.read<String>('id')],
                );
              }
            }
          }
        },
        beforeOpen: (details) async {
          // Enable foreign key enforcement.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Deletes all user-generated data (puzzles, progress, settings) while
  /// preserving the seed rows in [SourcesTable].
  ///
  /// Cascade rules mean deleting from [PuzzlesTable] automatically removes all
  /// dependent [CluesTable], [SolveSessionsTable], and [CellProgressTable] rows.
  /// Called from the Settings → "Clear all data" action.
  ///
  /// **Idempotency note (T5 verification):** [sourcesTable] is intentionally
  /// NOT cleared here. The seed rows inserted during [onCreate] (e.g.
  /// `local_import`) remain intact after this call, so no re-seeding is
  /// needed. See test `preserves sources seed row after clear` in
  /// `test/core/database/app_database_test.dart`.
  Future<void> clearAllUserData() async {
    await transaction(() async {
      // Cascade from puzzlesTable already removes dependent rows in
      // solve_sessions, cell_progress, clues, and puzzle_completions. We
      // explicitly delete puzzle_completions afterward as a defensive sweep
      // in case any row was ever orphaned by a future migration that loosens
      // the FK constraint.
      await delete(puzzlesTable).go();
      await delete(puzzleCompletionsTable).go();
      await delete(importedSolveStatsTable).go();
      await delete(appSettingsTable).go();
    });
  }

  /// Seeds all built-in sources on a fresh install.
  Future<void> _seedBuiltInSources() async {
    await _seedLocalImportSource();
    // Full ORM insert for fresh installs — schema is guaranteed complete.
    final now = DateTime.now().toUtc();
    await into(sourcesTable).insertOnConflictUpdate(
      SourcesTableCompanion.insert(
        id: 'crosshare_daily_mini',
        displayName: 'Crosshare Daily Mini',
        type: 'remote',
        homepageUrl: const Value('https://crosshare.org'),
        licenseStatus: const Value(LicenseStatus.explicitPermission),
        enabled: const Value(true),
        attributionRequired: const Value(true),
        rawPayloadRetention: const Value(false),
        commercialUseAllowed: const Value(false),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Insert the built-in 'local_import' pseudo-source.
  Future<void> _seedLocalImportSource() async {
    final now = DateTime.now().toUtc();
    await into(sourcesTable).insertOnConflictUpdate(
      SourcesTableCompanion.insert(
        id: 'local_import',
        displayName: 'Local Import',
        type: 'local',
        licenseStatus: const Value(LicenseStatus.userImport),
        enabled: const Value(true),
        attributionRequired: const Value(false),
        rawPayloadRetention: const Value(false),
        commercialUseAllowed: const Value(false),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Seeds the 'crosshare_daily_mini' source row during schema migration.
  ///
  /// This intentionally duplicates the fresh-install seed row in
  /// [_seedBuiltInSources], but uses raw SQL with only the columns present in
  /// the minimal historical schemas. That keeps v1/v2 databases migratable even
  /// when newer ORM columns did not exist yet. The migration tests in
  /// `test/core/database/app_database_test.dart` cover this path.
  Future<void> _seedCrosshareSource() async {
    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    await customInsert(
      'INSERT OR IGNORE INTO sources '
      '(id, display_name, type, enabled, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        const Variable<String>('crosshare_daily_mini'),
        const Variable<String>('Crosshare Daily Mini'),
        const Variable<String>('remote'),
        const Variable<bool>(true),
        Variable<int>(nowMs),
        Variable<int>(nowMs),
      ],
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'crosscue.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Migration helper: counts non-black cells in a puzzle's `canonical_json`
/// blob without going through `GridSerializer` (that would pull the full
/// `Puzzle` domain model into the migration path, which is intentionally
/// kept dependency-light).
///
/// Returns `null` on any parse error so the v5 → v6 migration can leave
/// the column at its 0 default for that row instead of aborting the entire
/// upgrade for one malformed payload. The `PuzzleDao.insertPuzzle` write
/// path computes the count from the in-memory grid and is authoritative
/// for every future insert.
int? _fillableCellCountFromCanonicalJson(String canonicalJson) {
  try {
    final decoded = jsonDecode(canonicalJson);
    if (decoded is! Map) return null;
    final rows = decoded['cells'];
    if (rows is! List) return null;
    var count = 0;
    for (final row in rows) {
      if (row is! List) return null;
      for (final cell in row) {
        if (cell is! Map) return null;
        if (cell['black'] != true) count++;
      }
    }
    return count;
  } on Object {
    return null;
  }
}
