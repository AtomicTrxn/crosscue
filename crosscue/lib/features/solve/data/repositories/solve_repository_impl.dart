import 'package:intl/intl.dart';

import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/enums.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/models/grid.dart';
import 'package:crosscue/features/solve/domain/models/puzzle.dart';
import 'package:crosscue/features/solve/domain/repositories/solve_repository.dart';
import 'package:crosscue/features/solve/data/daos/solve_session_dao.dart';

class SolveRepositoryImpl implements SolveRepository {
  const SolveRepositoryImpl({required this.dao});

  final SolveSessionDao dao;

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  /// Finds an existing in-progress session for [puzzle.id], or creates one.
  /// Restores cell-progress from DB when resuming.
  @override
  Future<SessionLoadResult> createOrResumeSession(Puzzle puzzle) async {
    final existing = await dao.findActiveSession(puzzle.id);

    if (existing != null) {
      final rows = await dao.loadCellProgress(existing.id);
      final progress = _buildProgressGrid(puzzle, rows);
      final focus = FocusPosition(
        row: existing.focusRow,
        col: existing.focusCol,
        direction: Direction.values.byName(existing.direction),
      );
      return SessionLoadResult(
        sessionId: existing.id,
        progress: progress,
        focus: focus,
        elapsedMs: existing.elapsedMs,
        isPaused: existing.isPaused,
        isResumed: true,
        checkCount: existing.checkCount,
        revealCount: existing.revealCount,
        usedCheck: existing.usedCheck,
        usedReveal: existing.usedReveal,
        cleanSolveEligible: existing.cleanSolveEligible,
      );
    }

    // Create a new session
    final id = await dao.createSession(puzzle.id);

    // Default focus: first non-black cell
    FocusPosition focus = const FocusPosition(
      row: 0,
      col: 0,
      direction: Direction.across,
    );
    outer:
    for (var r = 0; r < puzzle.height; r++) {
      for (var c = 0; c < puzzle.width; c++) {
        if (!puzzle.grid.cell(r, c).isBlack) {
          focus = FocusPosition(row: r, col: c, direction: Direction.across);
          break outer;
        }
      }
    }

    final blankProgress = Grid<CellProgress>.generate(
      puzzle.width,
      puzzle.height,
      (_, __) => CellProgress.blank,
    );

    return SessionLoadResult(
      sessionId: id,
      progress: blankProgress,
      focus: focus,
      elapsedMs: 0,
      isPaused: false,
      isResumed: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Autosave
  // ---------------------------------------------------------------------------

  /// Saves session state and all non-empty cell-progress rows.
  @override
  Future<void> saveProgress({
    required int sessionId,
    required int puzzleWidth,
    required int puzzleHeight,
    required Grid<CellProgress> progress,
    required FocusPosition focus,
    required int elapsedMs,
    required PuzzleStatus status,
    required bool isPaused,
    required int checkCount,
    required int revealCount,
    required bool usedCheck,
    required bool usedReveal,
    required bool cleanSolveEligible,
  }) async {
    await dao.updateSession(
      sessionId: sessionId,
      elapsedMs: elapsedMs,
      focusRow: focus.row,
      focusCol: focus.col,
      direction: focus.direction.name,
      status: _statusToDb(status),
      isPaused: isPaused,
      checkCount: checkCount,
      revealCount: revealCount,
      usedCheck: usedCheck,
      usedReveal: usedReveal,
      cleanSolveEligible: cleanSolveEligible,
    );

    await dao.saveCellProgress(sessionId, progress, puzzleWidth, puzzleHeight);
  }

  /// Saves the final completed/revealed state of a session.
  @override
  Future<void> markComplete({
    required int sessionId,
    required int puzzleWidth,
    required int puzzleHeight,
    required Grid<CellProgress> progress,
    required FocusPosition focus,
    required int elapsedMs,
    required PuzzleStatus status,
    required CompletionType completionType,
    required int checkCount,
    required int revealCount,
    required bool usedCheck,
    required bool usedReveal,
    required bool cleanSolveEligible,
  }) async {
    final now = DateTime.now();
    final solvedDateLocal = DateFormat('yyyy-MM-dd').format(now);
    final solvedTimezone = now.timeZoneName;

    await dao.updateSession(
      sessionId: sessionId,
      elapsedMs: elapsedMs,
      focusRow: focus.row,
      focusCol: focus.col,
      direction: focus.direction.name,
      status: _statusToDb(status),
      isPaused: false,
      checkCount: checkCount,
      revealCount: revealCount,
      usedCheck: usedCheck,
      usedReveal: usedReveal,
      cleanSolveEligible: cleanSolveEligible,
      completionType: completionType.name,
      completedAt: now.toUtc(),
      solvedDateLocal: solvedDateLocal,
      solvedTimezone: solvedTimezone,
    );

    await dao.saveCellProgress(sessionId, progress, puzzleWidth, puzzleHeight);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds a full [Grid<CellProgress>] from raw DB rows, defaulting missing
  /// cells to [CellProgress.blank].
  Grid<CellProgress> _buildProgressGrid(Puzzle puzzle, List<dynamic> rows) {
    final map = <(int, int), dynamic>{};
    for (final row in rows) {
      map[(row.row as int, row.col as int)] = row;
    }

    return Grid<CellProgress>.generate(
      puzzle.width,
      puzzle.height,
      (r, c) {
        final row = map[(r, c)];
        if (row == null) return CellProgress.blank;
        final letter = (row.guess as String?) ?? '';
        final state =
            CellState.values.byName((row.state as String?) ?? 'empty');
        final isPencil = (row.isPencil as bool?) ?? false;
        return CellProgress(letter: letter, state: state, isPencil: isPencil);
      },
    );
  }

  /// Maps [PuzzleStatus] to the DB string used in solve_sessions.status.
  String _statusToDb(PuzzleStatus s) => switch (s) {
        PuzzleStatus.unsolved => 'not_started',
        PuzzleStatus.inProgress => 'in_progress',
        PuzzleStatus.solved => 'completed',
        PuzzleStatus.solvedWithHelp => 'completed',
        PuzzleStatus.solvedWithReveal => 'completed',
        PuzzleStatus.revealed => 'revealed',
      };
}
