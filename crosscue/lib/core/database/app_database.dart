import 'dart:io';

import 'package:crosscue/core/database/tables/app_settings_table.dart';
import 'package:crosscue/core/database/tables/cell_progress_table.dart';
import 'package:crosscue/core/database/tables/clues_table.dart';
import 'package:crosscue/core/database/tables/imported_solve_stats_table.dart';
import 'package:crosscue/core/database/tables/puzzles_table.dart';
import 'package:crosscue/core/database/tables/solve_sessions_table.dart';
import 'package:crosscue/core/database/tables/sources_table.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/import/data/daos/puzzle_dao.dart';
import 'package:crosscue/features/settings/data/daos/app_settings_dao.dart';
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

  @override
  int get schemaVersion => 2;

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
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedLocalImportSource();
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
      await delete(puzzlesTable).go();
      await delete(importedSolveStatsTable).go();
      await delete(appSettingsTable).go();
    });
  }

  /// Insert the built-in 'local_import' pseudo-source on first launch.
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'crosscue.db'));
    return NativeDatabase.createInBackground(file);
  });
}
