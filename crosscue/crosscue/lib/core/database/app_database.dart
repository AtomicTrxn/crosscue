import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/import/data/daos/puzzle_dao.dart';
import '../../features/solve/data/daos/solve_session_dao.dart';
import '../../features/solve/domain/models/enums.dart';
import '../settings/app_settings_dao.dart';
import 'tables/app_settings_table.dart';
import 'tables/cell_progress_table.dart';
import 'tables/clues_table.dart';
import 'tables/puzzles_table.dart';
import 'tables/solve_sessions_table.dart';
import 'tables/sources_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  SourcesTable,
  PuzzlesTable,
  CluesTable,
  SolveSessionsTable,
  CellProgressTable,
  AppSettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Expose for testing — accepts an in-memory executor.
  AppDatabase.forTesting(super.executor);

  /// DAO accessors
  PuzzleDao get puzzleDao => PuzzleDao(this);
  SolveSessionDao get solveSessionDao => SolveSessionDao(this);
  AppSettingsDao get appSettingsDao => AppSettingsDao(this);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedLocalImportSource();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here.
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
  Future<void> clearAllUserData() async {
    await transaction(() async {
      await delete(puzzlesTable).go();
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
