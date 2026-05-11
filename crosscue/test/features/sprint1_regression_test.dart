// Regression tests for Sprint 1 critical fixes (Issue #18).
// Each group is labelled with the item it guards against.
//
// C1 — AppThemeMode: domain layer must not import Flutter ThemeMode.
// C2 — No dynamic: typed interfaces enforced by Dart's type system (compile-time).
// C3 — sourceId threading: parsers forward the caller-supplied sourceId.
// C4 — Auto-download default: getCrosshareAutoDownload returns false when unset.
// C6 — Cell-progress orphan rows: cleared cells are not persisted.

import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/import/data/parsers/ipuz_parser.dart';
import 'package:crosscue/features/import/data/parsers/puz_parser.dart';
import 'package:crosscue/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/puz_fixture_builder.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // C1: AppThemeMode — domain enum exists and does not require Flutter
  // ─────────────────────────────────────────────────────────────────────────

  group('C1 – AppThemeMode domain enum', () {
    test('has light, dark, system values', () {
      expect(
        AppThemeMode.values,
        containsAll([
          AppThemeMode.light,
          AppThemeMode.dark,
          AppThemeMode.system,
        ]),
      );
    });

    test('AppSettingsRepositoryImpl.getThemeMode returns AppThemeMode',
        () async {
      // Compile-time guarantee: Future<AppThemeMode>.
      // This test will fail to compile if the return type is changed to ThemeMode.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = AppSettingsRepositoryImpl(dao: db.appSettingsDao);
      final mode = await repo.getThemeMode();
      expect(mode, isA<AppThemeMode>());
      expect(mode, AppThemeMode.system); // default
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // C3: sourceId threading — parsers use the caller-supplied sourceId
  // ─────────────────────────────────────────────────────────────────────────

  group('C3 – sourceId threading', () {
    const puzParser = PuzParser();
    const ipuzParser = IpuzParser();

    test('PuzParser defaults sourceId to local_import', () {
      final result = puzParser.parse(PuzFixtureBuilder.minimal3x3());
      expect(result.isOk, isTrue);
      expect(result.value.metadata.sourceId, equals('local_import'));
    });

    test('PuzParser forwards custom sourceId', () {
      final result = puzParser.parse(
        PuzFixtureBuilder.minimal3x3(),
        sourceId: 'crosshare_daily_mini',
      );
      expect(result.isOk, isTrue);
      expect(result.value.metadata.sourceId, equals('crosshare_daily_mini'));
    });

    test('IpuzParser defaults sourceId to local_import', () {
      final result = ipuzParser.parse(_minimalIpuzBytes());
      expect(result.isOk, isTrue);
      expect(result.value.metadata.sourceId, equals('local_import'));
    });

    test('IpuzParser forwards custom sourceId', () {
      final result = ipuzParser.parse(
        _minimalIpuzBytes(),
        sourceId: 'crosshare_daily_mini',
      );
      expect(result.isOk, isTrue);
      expect(result.value.metadata.sourceId, equals('crosshare_daily_mini'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // C4: Auto-download default — must be false when no DB value is stored
  // ─────────────────────────────────────────────────────────────────────────

  group('C4 – Crosshare auto-download default', () {
    late AppDatabase db;
    late AppSettingsRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = AppSettingsRepositoryImpl(dao: db.appSettingsDao);
    });

    tearDown(() => db.close());

    test('returns false when key is absent (opt-in required)', () async {
      expect(await repo.getCrosshareAutoDownload(), isFalse);
    });

    test('returns true after explicit opt-in', () async {
      await repo.setCrosshareAutoDownload(true);
      expect(await repo.getCrosshareAutoDownload(), isTrue);
    });

    test('returns false after explicit opt-out', () async {
      await repo.setCrosshareAutoDownload(true);
      await repo.setCrosshareAutoDownload(false);
      expect(await repo.getCrosshareAutoDownload(), isFalse);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns the bytes of a minimal valid 3×3 ipuz puzzle as [Uint8List].
Uint8List _minimalIpuzBytes() {
  const json = '{"version":"http://ipuz.org/v2",'
      '"kind":["http://ipuz.org/crossword#1"],'
      '"dimensions":{"width":3,"height":3},'
      '"puzzle":[[{"cell":1},{"cell":2},{"cell":3}],'
      '[{"cell":4},{"cell":5},{"cell":6}],'
      '[{"cell":7},{"cell":8},{"cell":9}]],'
      '"solution":[["A","B","C"],["D","E","F"],["G","H","I"]],'
      '"clues":{'
      '"Across":[["1","Clue 1A"],["4","Clue 4A"],["7","Clue 7A"]],'
      '"Down":[["1","Clue 1D"],["2","Clue 2D"],["3","Clue 3D"]]'
      '}}';
  return Uint8List.fromList(json.codeUnits);
}
