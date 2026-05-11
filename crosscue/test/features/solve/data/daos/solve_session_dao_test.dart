// Tests for SolveSessionDao — session lifecycle and cell-progress CRUD.
//
// C6 regression: clearing cells must remove their DB rows (no orphan rows).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<String> insertPuzzle({String id = 'test:puzzle'}) async {
    final now = DateTime.now().toUtc();
    await db.into(db.puzzlesTable).insert(
          PuzzlesTableCompanion.insert(
            id: id,
            sourceId: 'local_import',
            format: 'puz',
            title: 'Test Puzzle',
            width: 3,
            height: 3,
            checksum: id,
            canonicalJson: '{}',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Grid<CellProgress> grid({String letter = '', bool blank = false}) {
    return Grid<CellProgress>.generate(3, 3, (r, c) {
      if (blank) return CellProgress.blank;
      if (r == 0 && c == 0) return CellProgress(letter: letter);
      return CellProgress.blank;
    });
  }

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  group('createSession', () {
    test('inserts row and returns auto-increment id', () async {
      await insertPuzzle();
      final id = await db.solveSessionDao.createSession('test:puzzle');
      expect(id, isA<int>());
      expect(id, greaterThan(0));
    });

    test('two puzzles produce different session ids', () async {
      await insertPuzzle(id: 'test:p1');
      await insertPuzzle(id: 'test:p2');
      final id1 = await db.solveSessionDao.createSession('test:p1');
      final id2 = await db.solveSessionDao.createSession('test:p2');
      expect(id1, isNot(equals(id2)));
    });
  });

  group('findActiveSession', () {
    test('returns null when no session exists', () async {
      await insertPuzzle();
      final s = await db.solveSessionDao.findActiveSession('test:puzzle');
      expect(s, isNull);
    });

    test('returns the in_progress session after create', () async {
      await insertPuzzle();
      final id = await db.solveSessionDao.createSession('test:puzzle');
      final s = await db.solveSessionDao.findActiveSession('test:puzzle');
      expect(s, isNotNull);
      expect(s!.id, equals(id));
      expect(s.status, equals('in_progress'));
    });

    test('returns null after session is marked completed', () async {
      await insertPuzzle();
      final id = await db.solveSessionDao.createSession('test:puzzle');
      await db.solveSessionDao.updateSession(
        sessionId: id,
        elapsedMs: 60000,
        focusRow: 0,
        focusCol: 0,
        direction: 'across',
        status: 'completed',
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );
      final s = await db.solveSessionDao.findActiveSession('test:puzzle');
      expect(s, isNull);
    });
  });

  group('getLatestSession', () {
    test('returns null when no session exists', () async {
      await insertPuzzle();
      final s = await db.solveSessionDao.getLatestSession('test:puzzle');
      expect(s, isNull);
    });

    test('returns session regardless of status', () async {
      await insertPuzzle();
      final id = await db.solveSessionDao.createSession('test:puzzle');
      await db.solveSessionDao.updateSession(
        sessionId: id,
        elapsedMs: 30000,
        focusRow: 1,
        focusCol: 2,
        direction: 'down',
        status: 'completed',
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );
      final s = await db.solveSessionDao.getLatestSession('test:puzzle');
      expect(s, isNotNull);
      expect(s!.status, equals('completed'));
    });
  });

  group('updateSession', () {
    test('persists elapsedMs, focus, and status', () async {
      await insertPuzzle();
      final id = await db.solveSessionDao.createSession('test:puzzle');
      await db.solveSessionDao.updateSession(
        sessionId: id,
        elapsedMs: 45000,
        focusRow: 2,
        focusCol: 1,
        direction: 'down',
        status: 'in_progress',
        isPaused: true,
        checkCount: 2,
        revealCount: 1,
        usedCheck: true,
        usedReveal: false,
        cleanSolveEligible: false,
      );
      final s = await db.solveSessionDao.findActiveSession('test:puzzle');
      expect(s!.elapsedMs, equals(45000));
      expect(s.focusRow, equals(2));
      expect(s.focusCol, equals(1));
      expect(s.direction, equals('down'));
      expect(s.isPaused, isTrue);
      expect(s.checkCount, equals(2));
      expect(s.revealCount, equals(1));
      expect(s.usedCheck, isTrue);
      expect(s.usedReveal, isFalse);
      expect(s.cleanSolveEligible, isFalse);
    });

    test('persists completionType and solvedDateLocal', () async {
      await insertPuzzle();
      final id = await db.solveSessionDao.createSession('test:puzzle');
      await db.solveSessionDao.updateSession(
        sessionId: id,
        elapsedMs: 90000,
        focusRow: 0,
        focusCol: 0,
        direction: 'across',
        status: 'completed',
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
        completionType: 'clean',
        completedAt: DateTime.now().toUtc(),
        solvedDateLocal: '2025-06-01',
        solvedTimezone: 'America/Chicago',
      );
      final s = await db.solveSessionDao.getLatestSession('test:puzzle');
      expect(s!.completionType, equals('clean'));
      expect(s.solvedDateLocal, equals('2025-06-01'));
      expect(s.solvedTimezone, equals('America/Chicago'));
    });
  });

  // ---------------------------------------------------------------------------
  // Cell progress
  // ---------------------------------------------------------------------------

  group('saveCellProgress / loadCellProgress', () {
    test('round-trip: saves non-blank cells and retrieves them', () async {
      await insertPuzzle();
      final sessionId = await db.solveSessionDao.createSession('test:puzzle');
      final grid = Grid<CellProgress>.generate(3, 3, (r, c) {
        if (r == 0 && c == 0) {
          return const CellProgress(letter: 'A', state: CellState.empty);
        }
        if (r == 1 && c == 1) {
          return const CellProgress(
              letter: 'B', state: CellState.checkedCorrect);
        }
        return CellProgress.blank;
      });

      await db.solveSessionDao.saveCellProgress(sessionId, grid, 3, 3);
      final rows = await db.solveSessionDao.loadCellProgress(sessionId);

      expect(rows, hasLength(2));
      final r00 = rows.firstWhere((r) => r.row == 0 && r.col == 0);
      expect(r00.guess, equals('A'));
      expect(r00.state, equals('empty'));
      final r11 = rows.firstWhere((r) => r.row == 1 && r.col == 1);
      expect(r11.guess, equals('B'));
      expect(r11.state, equals('checkedCorrect'));
    });

    test('blank grid produces no rows in DB', () async {
      await insertPuzzle();
      final sessionId = await db.solveSessionDao.createSession('test:puzzle');
      final blankGrid =
          Grid<CellProgress>.generate(3, 3, (_, __) => CellProgress.blank);

      await db.solveSessionDao.saveCellProgress(sessionId, blankGrid, 3, 3);
      final rows = await db.solveSessionDao.loadCellProgress(sessionId);
      expect(rows, isEmpty);
    });

    test('cell (0, 0) is a valid coordinate and is persisted', () async {
      await insertPuzzle();
      final sessionId = await db.solveSessionDao.createSession('test:puzzle');
      final grid =
          Grid<CellProgress>.generate(3, 3, (r, c) => CellProgress.blank)
              .withCell(0, 0, const CellProgress(letter: 'Z'));

      await db.solveSessionDao.saveCellProgress(sessionId, grid, 3, 3);
      final rows = await db.solveSessionDao.loadCellProgress(sessionId);
      expect(
          rows.any((r) => r.row == 0 && r.col == 0 && r.guess == 'Z'), isTrue);
    });

    // ── C6 regression ──────────────────────────────────────────────────────

    test('C6: backspace — clearing a cell removes its DB row', () async {
      await insertPuzzle();
      final sessionId = await db.solveSessionDao.createSession('test:puzzle');

      // Save with a letter at (0,0)
      await db.solveSessionDao
          .saveCellProgress(sessionId, grid(letter: 'X'), 3, 3);
      expect(
          await db.solveSessionDao.loadCellProgress(sessionId), hasLength(1));

      // Clear (backspace) → save blank grid
      await db.solveSessionDao
          .saveCellProgress(sessionId, grid(blank: true), 3, 3);
      expect(await db.solveSessionDao.loadCellProgress(sessionId), isEmpty);
    });

    test('C6: reset — all progress rows removed after save of blank grid',
        () async {
      await insertPuzzle();
      final sessionId = await db.solveSessionDao.createSession('test:puzzle');

      // Fill several cells
      final full = Grid<CellProgress>.generate(3, 3,
          (r, c) => CellProgress(letter: String.fromCharCode(65 + r * 3 + c)));
      await db.solveSessionDao.saveCellProgress(sessionId, full, 3, 3);
      expect(
          await db.solveSessionDao.loadCellProgress(sessionId), hasLength(9));

      // Reset to blank
      await db.solveSessionDao.saveCellProgress(
          sessionId,
          Grid<CellProgress>.generate(3, 3, (_, __) => CellProgress.blank),
          3,
          3);
      expect(await db.solveSessionDao.loadCellProgress(sessionId), isEmpty);
    });

    test('C6: overwrite — second save replaces first, no duplicate rows',
        () async {
      await insertPuzzle();
      final sessionId = await db.solveSessionDao.createSession('test:puzzle');

      await db.solveSessionDao
          .saveCellProgress(sessionId, grid(letter: 'A'), 3, 3);
      await db.solveSessionDao
          .saveCellProgress(sessionId, grid(letter: 'B'), 3, 3);

      final rows = await db.solveSessionDao.loadCellProgress(sessionId);
      expect(rows, hasLength(1));
      expect(rows.first.guess, equals('B'));
    });

    test('multiple sessions are isolated', () async {
      await insertPuzzle(id: 'test:p1');
      await insertPuzzle(id: 'test:p2');
      final s1 = await db.solveSessionDao.createSession('test:p1');
      final s2 = await db.solveSessionDao.createSession('test:p2');

      await db.solveSessionDao.saveCellProgress(s1, grid(letter: 'X'), 3, 3);
      await db.solveSessionDao.saveCellProgress(s2, grid(letter: 'Y'), 3, 3);

      final r1 = await db.solveSessionDao.loadCellProgress(s1);
      final r2 = await db.solveSessionDao.loadCellProgress(s2);

      expect(r1.first.guess, equals('X'));
      expect(r2.first.guess, equals('Y'));
      // No cross-pollution
      expect(r1.any((r) => r.guess == 'Y'), isFalse);
    });

    test('isPencil flag is persisted and retrieved', () async {
      await insertPuzzle();
      final sessionId = await db.solveSessionDao.createSession('test:puzzle');
      final grid =
          Grid<CellProgress>.generate(3, 3, (_, __) => CellProgress.blank)
              .withCell(0, 0, const CellProgress(letter: 'P', isPencil: true));
      await db.solveSessionDao.saveCellProgress(sessionId, grid, 3, 3);

      final rows = await db.solveSessionDao.loadCellProgress(sessionId);
      expect(rows.first.isPencil, isTrue);
    });
  });
}
