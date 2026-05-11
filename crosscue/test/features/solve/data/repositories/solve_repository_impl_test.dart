// Tests for SolveRepositoryImpl — session create/resume and progress persistence.

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/features/import/data/repositories/import_repository_impl.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/solve/data/repositories/solve_repository_impl.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/puz_fixture_builder.dart';

void main() {
  late AppDatabase db;
  late SolveRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SolveRepositoryImpl(dao: db.solveSessionDao);
  });
  tearDown(() => db.close());

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Imports a minimal 3×3 puzzle and returns its ID.
  Future<String> importPuzzle() async {
    final importRepo = ImportRepositoryImpl(dao: db.puzzleDao);
    final result = await importRepo.importBytes(PuzFixtureBuilder.minimal3x3());
    return switch (result) {
      JobSuccess(:final puzzle) => puzzle.id,
      JobDuplicate() => throw StateError('unexpected duplicate'),
      JobFailure(:final error) => throw StateError('import failed: $error'),
    };
  }

  Grid<CellProgress> blankGrid({int w = 3, int h = 3}) =>
      Grid<CellProgress>.generate(w, h, (_, __) => CellProgress.blank);

  const defaultFocus =
      FocusPosition(row: 0, col: 0, direction: Direction.across);

  // ---------------------------------------------------------------------------
  // createOrResumeSession
  // ---------------------------------------------------------------------------

  group('createOrResumeSession', () {
    test('creates a new session and returns a blank progress grid', () async {
      final puzzleId = await importPuzzle();
      final puzzle = (await db.puzzleDao.getPuzzle(puzzleId))!;

      final result = await repo.createOrResumeSession(puzzle);
      expect(result.isResumed, isFalse);
      expect(result.sessionId, greaterThan(0));
      expect(result.elapsedMs, equals(0));
      expect(result.isPaused, isFalse);
      // All cells should be blank
      for (var r = 0; r < puzzle.height; r++) {
        for (var c = 0; c < puzzle.width; c++) {
          expect(result.progress.cell(r, c), equals(CellProgress.blank));
        }
      }
    });

    test('focus defaults to first non-black cell (0,0) for all-white puzzle',
        () async {
      final puzzleId = await importPuzzle();
      final puzzle = (await db.puzzleDao.getPuzzle(puzzleId))!;

      final result = await repo.createOrResumeSession(puzzle);
      expect(result.focus.row, equals(0));
      expect(result.focus.col, equals(0));
    });

    test('resuming an existing session restores progress', () async {
      final puzzleId = await importPuzzle();
      final puzzle = (await db.puzzleDao.getPuzzle(puzzleId))!;

      // Create session and save some progress
      final created = await repo.createOrResumeSession(puzzle);
      final progressWithLetter = Grid<CellProgress>.generate(3, 3, (r, c) {
        if (r == 0 && c == 0) return const CellProgress(letter: 'A');
        return CellProgress.blank;
      });
      await repo.saveProgress(
        sessionId: created.sessionId,
        puzzleWidth: 3,
        puzzleHeight: 3,
        progress: progressWithLetter,
        focus: const FocusPosition(row: 0, col: 1, direction: Direction.across),
        elapsedMs: 12000,
        status: PuzzleStatus.inProgress,
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );

      // Resume
      final resumed = await repo.createOrResumeSession(puzzle);
      expect(resumed.isResumed, isTrue);
      expect(resumed.sessionId, equals(created.sessionId));
      expect(resumed.elapsedMs, equals(12000));
      expect(resumed.focus.row, equals(0));
      expect(resumed.focus.col, equals(1));
      expect(resumed.progress.cell(0, 0).letter, equals('A'));
    });

    test('resumed session has the same session id as the original', () async {
      final puzzleId = await importPuzzle();
      final puzzle = (await db.puzzleDao.getPuzzle(puzzleId))!;

      final s1 = await repo.createOrResumeSession(puzzle);
      final s2 = await repo.createOrResumeSession(puzzle);

      expect(s1.sessionId, equals(s2.sessionId));
    });
  });

  // ---------------------------------------------------------------------------
  // saveProgress
  // ---------------------------------------------------------------------------

  group('saveProgress', () {
    test('persists elapsedMs and focus', () async {
      final puzzleId = await importPuzzle();
      final puzzle = (await db.puzzleDao.getPuzzle(puzzleId))!;
      final session = await repo.createOrResumeSession(puzzle);

      await repo.saveProgress(
        sessionId: session.sessionId,
        puzzleWidth: 3,
        puzzleHeight: 3,
        progress: blankGrid(),
        focus: const FocusPosition(row: 2, col: 1, direction: Direction.down),
        elapsedMs: 55000,
        status: PuzzleStatus.inProgress,
        isPaused: true,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );

      final resumed = await repo.createOrResumeSession(puzzle);
      expect(resumed.elapsedMs, equals(55000));
      expect(resumed.focus.row, equals(2));
      expect(resumed.focus.col, equals(1));
      expect(resumed.focus.direction, equals(Direction.down));
      expect(resumed.isPaused, isTrue);
    });

    test('non-blank cells are persisted and survive a resume', () async {
      final puzzleId = await importPuzzle();
      final puzzle = (await db.puzzleDao.getPuzzle(puzzleId))!;
      final session = await repo.createOrResumeSession(puzzle);

      final progress = Grid<CellProgress>.generate(3, 3, (r, c) {
        if (r == 1 && c == 2) {
          return const CellProgress(
            letter: 'Q',
            state: CellState.checkedCorrect,
          );
        }
        return CellProgress.blank;
      });

      await repo.saveProgress(
        sessionId: session.sessionId,
        puzzleWidth: 3,
        puzzleHeight: 3,
        progress: progress,
        focus: defaultFocus,
        elapsedMs: 0,
        status: PuzzleStatus.inProgress,
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );

      final resumed = await repo.createOrResumeSession(puzzle);
      expect(resumed.progress.cell(1, 2).letter, equals('Q'));
      expect(
        resumed.progress.cell(1, 2).state,
        equals(CellState.checkedCorrect),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // markComplete
  // ---------------------------------------------------------------------------

  group('markComplete', () {
    test('sets completionType and solvedDateLocal on the session', () async {
      final puzzleId = await importPuzzle();
      final puzzle = (await db.puzzleDao.getPuzzle(puzzleId))!;
      final session = await repo.createOrResumeSession(puzzle);

      await repo.markComplete(
        sessionId: session.sessionId,
        puzzleWidth: 3,
        puzzleHeight: 3,
        progress: blankGrid(),
        focus: defaultFocus,
        elapsedMs: 88000,
        status: PuzzleStatus.solved,
        completionType: CompletionType.clean,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );

      final row = await db.solveSessionDao.getLatestSession(puzzleId);
      expect(row!.completionType, equals('clean'));
      expect(row.solvedDateLocal, isNotNull);
      expect(row.solvedDateLocal!.length, equals(10)); // yyyy-MM-dd
      expect(row.elapsedMs, equals(88000));
    });
  });

  // ---------------------------------------------------------------------------
  // _buildProgressGrid (tested indirectly via resume)
  // ---------------------------------------------------------------------------

  group('_buildProgressGrid', () {
    test('missing cells default to CellProgress.blank', () async {
      final puzzleId = await importPuzzle();
      final puzzle = (await db.puzzleDao.getPuzzle(puzzleId))!;
      final session = await repo.createOrResumeSession(puzzle);

      // Save only one cell
      final partial = Grid<CellProgress>.generate(3, 3, (r, c) {
        if (r == 0 && c == 0) return const CellProgress(letter: 'Z');
        return CellProgress.blank;
      });
      await repo.saveProgress(
        sessionId: session.sessionId,
        puzzleWidth: 3,
        puzzleHeight: 3,
        progress: partial,
        focus: defaultFocus,
        elapsedMs: 0,
        status: PuzzleStatus.inProgress,
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );

      final resumed = await repo.createOrResumeSession(puzzle);
      // (0,0) has the letter
      expect(resumed.progress.cell(0, 0).letter, equals('Z'));
      // All other cells are blank
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          if (r == 0 && c == 0) continue;
          expect(resumed.progress.cell(r, c), equals(CellProgress.blank));
        }
      }
    });

    test('C6 regression: cleared cells are blank on resume', () async {
      final puzzleId = await importPuzzle();
      final puzzle = (await db.puzzleDao.getPuzzle(puzzleId))!;
      final session = await repo.createOrResumeSession(puzzle);

      // Save a filled grid
      final filled = Grid<CellProgress>.generate(
        3,
        3,
        (_, __) => const CellProgress(letter: 'A'),
      );
      await repo.saveProgress(
        sessionId: session.sessionId,
        puzzleWidth: 3,
        puzzleHeight: 3,
        progress: filled,
        focus: defaultFocus,
        elapsedMs: 0,
        status: PuzzleStatus.inProgress,
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );

      // Clear all cells (reset)
      await repo.saveProgress(
        sessionId: session.sessionId,
        puzzleWidth: 3,
        puzzleHeight: 3,
        progress: blankGrid(),
        focus: defaultFocus,
        elapsedMs: 0,
        status: PuzzleStatus.inProgress,
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );

      final resumed = await repo.createOrResumeSession(puzzle);
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          expect(
            resumed.progress.cell(r, c),
            equals(CellProgress.blank),
            reason: 'cell ($r,$c) should be blank after reset',
          );
        }
      }
    });
  });
}
