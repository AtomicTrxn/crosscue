// Tests for ImportRepositoryImpl — parse dispatch, duplicate detection,
// sourceId threading (C3 regression), and DB persistence.

import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/import/data/repositories/import_repository_impl.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/ipuz_fixture.dart';
import '../../../../helpers/puz_fixture_builder.dart';

void main() {
  late AppDatabase db;
  late ImportRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ImportRepositoryImpl(dao: db.puzzleDao);
  });
  tearDown(() => db.close());

  /// Seeds an extra source row so FK constraints allow that sourceId.
  Future<void> seedSource(String id) async {
    final now = DateTime.now().toUtc();
    await db.into(db.sourcesTable).insertOnConflictUpdate(
          SourcesTableCompanion.insert(
            id: id,
            displayName: id,
            type: 'external',
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // .puz imports
  // ---------------------------------------------------------------------------

  group('.puz import', () {
    test('success: returns JobSuccess and persists puzzle', () async {
      final result = await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      expect(result, isA<JobSuccess>());
      final puzzleId = (result as JobSuccess).puzzle.id;
      final fetched = await db.puzzleDao.getPuzzle(puzzleId);
      expect(fetched, isNotNull);
      expect(fetched!.metadata.title, equals('Test Puzzle'));
    });

    test('success: returned puzzle has correct dimensions', () async {
      final result = await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      final puzzle = (result as JobSuccess).puzzle;
      expect(puzzle.width, equals(3));
      expect(puzzle.height, equals(3));
    });

    test('sourceId defaults to local_import', () async {
      final result = await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      final puzzle = (result as JobSuccess).puzzle;
      expect(puzzle.metadata.sourceId, equals('local_import'));
    });

    test('sourceId is threaded through to the saved puzzle (C3)', () async {
      await seedSource('crosshare_daily_mini');
      final result = await repo.importBytes(
        PuzFixtureBuilder.minimal3x3(),
        sourceId: 'crosshare_daily_mini',
      );
      final puzzle = (result as JobSuccess).puzzle;
      expect(puzzle.metadata.sourceId, equals('crosshare_daily_mini'));
    });

    test('duplicate: second import returns JobDuplicate', () async {
      await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      final second = await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      expect(second, isA<JobDuplicate>());
    });

    test('failure: invalid bytes return JobFailure', () async {
      final result =
          await repo.importBytes(Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]));
      expect(result, isA<JobFailure>());
      expect((result as JobFailure).error, equals(ParseError.invalidFormat));
    });
  });

  // ---------------------------------------------------------------------------
  // .ipuz imports
  // ---------------------------------------------------------------------------

  group('.ipuz import', () {
    test('success: returns JobSuccess for valid ipuz bytes', () async {
      final result = await repo.importBytes(IpuzFixture.minimal3x3());
      expect(result, isA<JobSuccess>());
    });

    test('sourceId is threaded through for ipuz files (C3)', () async {
      await seedSource('crosshare_daily_mini');
      final result = await repo.importBytes(
        IpuzFixture.minimal3x3(),
        sourceId: 'crosshare_daily_mini',
      );
      final puzzle = (result as JobSuccess).puzzle;
      expect(puzzle.metadata.sourceId, equals('crosshare_daily_mini'));
    });

    test('duplicate ipuz import returns JobDuplicate', () async {
      await repo.importBytes(IpuzFixture.minimal3x3());
      final second = await repo.importBytes(IpuzFixture.minimal3x3());
      expect(second, isA<JobDuplicate>());
    });
  });

  // ---------------------------------------------------------------------------
  // Unsupported formats
  // ---------------------------------------------------------------------------

  group('unsupported formats', () {
    test('.jpz-like bytes return JobFailure until a parser exists', () async {
      final result = await repo.importBytes(
        Uint8List.fromList('{"kind":"jpz"}'.codeUnits),
      );

      expect(result, isA<JobFailure>());
      expect((result as JobFailure).error, equals(ParseError.invalidFormat));
    });
  });

  // ---------------------------------------------------------------------------
  // Metadata and retrieval
  // ---------------------------------------------------------------------------

  group('getAllMetadata / getPuzzle / deletePuzzle', () {
    test('getAllMetadata returns empty list initially', () async {
      expect(await repo.getAllMetadata(), isEmpty);
    });

    test('getAllMetadata returns imported puzzle', () async {
      await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      final metas = await repo.getAllMetadata();
      expect(metas, hasLength(1));
      expect(metas.first.title, equals('Test Puzzle'));
    });

    test('getPuzzle returns null for unknown id', () async {
      expect(await repo.getPuzzle('nonexistent:id'), isNull);
    });

    test('getPuzzle returns full puzzle after import', () async {
      final result = await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      final id = (result as JobSuccess).puzzle.id;
      final puzzle = await repo.getPuzzle(id);
      expect(puzzle, isNotNull);
      expect(puzzle!.clues, isNotEmpty);
    });

    test('deletePuzzle removes puzzle from DB', () async {
      final result = await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      final id = (result as JobSuccess).puzzle.id;
      await repo.deletePuzzle(id);
      expect(await repo.getPuzzle(id), isNull);
      expect(await repo.getAllMetadata(), isEmpty);
    });

    test('multiple imports: getAllMetadata returns all', () async {
      await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      await repo.importBytes(IpuzFixture.minimal3x3());
      expect(await repo.getAllMetadata(), hasLength(2));
    });

    // ------------------------------------------------------------------
    // fillable_cell_count denormalization (#122)
    // ------------------------------------------------------------------

    test('insertPuzzle denormalizes fillable_cell_count onto the row',
        () async {
      // PuzFixtureBuilder.minimal3x3 produces a 3×3 grid where every cell
      // is fillable — see test/helpers/puz_fixture_builder.dart — so the
      // denormalized count must be 9.
      final result = await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      final meta = (result as JobSuccess).puzzle.metadata;

      final stored = await db.puzzleDao.getMetadata(meta.id);
      expect(stored, isNotNull);
      expect(
        stored!.fillableCellCount,
        equals(9),
        reason: 'a 3×3 grid with no black cells must denormalize to 9 '
            'fillable cells at import time so Archive / Stats can read '
            'progress without JSON-decoding canonical_json',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // sourcePuzzleId — stable ID from remote sources (e.g. Crosshare)
  // ---------------------------------------------------------------------------

  group('sourcePuzzleId', () {
    test('persists sourcePuzzleId from importBytes onto the puzzle row',
        () async {
      await seedSource('crosshare_daily_mini');
      final result = await repo.importBytes(
        PuzFixtureBuilder.minimal3x3(),
        sourceId: 'crosshare_daily_mini',
        sourcePuzzleId: 'cs-puzzle-abc',
      );
      expect(result, isA<JobSuccess>());
      final meta = (result as JobSuccess).puzzle.metadata;
      expect(meta.sourcePuzzleId, 'cs-puzzle-abc');

      final fetched = await db.puzzleDao.getMetadata(meta.id);
      expect(fetched?.sourcePuzzleId, 'cs-puzzle-abc');
    });

    test('importBytes returns JobDuplicate when sourcePuzzleId already exists',
        () async {
      await seedSource('crosshare_daily_mini');
      final first = await repo.importBytes(
        PuzFixtureBuilder.minimal3x3(),
        sourceId: 'crosshare_daily_mini',
        sourcePuzzleId: 'cs-puzzle-abc',
      );
      expect(first, isA<JobSuccess>());

      // Different bytes, same (sourceId, sourcePuzzleId) → fast-path duplicate.
      final second = await repo.importBytes(
        IpuzFixture.minimal3x3(),
        sourceId: 'crosshare_daily_mini',
        sourcePuzzleId: 'cs-puzzle-abc',
      );
      expect(second, isA<JobDuplicate>());
    });

    test(
        'existsBySourcePuzzleId is false for an unknown (sourceId, '
        'sourcePuzzleId) pair', () async {
      expect(
        await db.puzzleDao.existsBySourcePuzzleId(
          'crosshare_daily_mini',
          'never-imported',
        ),
        isFalse,
      );
    });

    test('local imports leave sourcePuzzleId null', () async {
      final result = await repo.importBytes(PuzFixtureBuilder.minimal3x3());
      final meta = (result as JobSuccess).puzzle.metadata;
      expect(meta.sourcePuzzleId, isNull);
    });
  });
}
