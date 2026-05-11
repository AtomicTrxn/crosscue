import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/domain/repositories/archive_repository.dart';
import 'package:crosscue/features/import/data/daos/puzzle_dao.dart';
import 'package:crosscue/features/solve/data/daos/solve_session_dao.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';

/// Provides the Archive screen's data by combining [PuzzleDao] metadata with
/// the latest [SolveSessionRow] for each puzzle.
///
/// Uses an N+1 pattern (one latestSession query per puzzle) which is
/// acceptable for Phase 1 (import-only, typically <100 puzzles).
class ArchiveRepositoryImpl implements ArchiveRepository {
  const ArchiveRepositoryImpl({
    required this.puzzleDao,
    required this.sessionDao,
  });

  final PuzzleDao puzzleDao;
  final SolveSessionDao sessionDao;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns all puzzles merged with their latest session status, ordered by
  /// import date descending (most recent first).
  @override
  Future<List<ArchiveEntry>> getArchiveEntries() async {
    final allPuzzles = await puzzleDao.getAllMetadata();
    final entries = <ArchiveEntry>[];

    for (final puzzle in allPuzzles) {
      final session = await sessionDao.getLatestSession(puzzle.id);
      final completionFraction = await _completionFraction(puzzle.id, session);
      entries.add(_buildEntry(puzzle, session, completionFraction));
    }

    return entries;
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Deletes [puzzleId] and all dependent rows (clues, sessions, cell_progress)
  /// via the cascade rule defined in the DB schema.
  @override
  Future<void> deletePuzzle(String puzzleId) =>
      puzzleDao.deletePuzzle(puzzleId);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  ArchiveEntry _buildEntry(
    PuzzleMetadata puzzle,
    SolveSessionRow? session,
    double completionFraction,
  ) {
    if (session == null) {
      return ArchiveEntry(
        puzzleId: puzzle.id,
        title: puzzle.title,
        author: puzzle.author,
        width: puzzle.width,
        height: puzzle.height,
        importedAt: puzzle.importedAt,
        publishDate: puzzle.publishDate,
        sessionStatus: 'not_started',
        completionFraction: completionFraction,
      );
    }
    return ArchiveEntry(
      puzzleId: puzzle.id,
      title: puzzle.title,
      author: puzzle.author,
      width: puzzle.width,
      height: puzzle.height,
      importedAt: puzzle.importedAt,
      publishDate: puzzle.publishDate,
      sessionId: session.id,
      sessionStatus: session.status,
      completionType: session.completionType,
      elapsedMs: session.elapsedMs,
      completedAt: session.completedAt,
      lastPlayedAt: session.lastPlayedAt,
      completionFraction: completionFraction,
    );
  }

  Future<double> _completionFraction(
    String puzzleId,
    SolveSessionRow? session,
  ) async {
    if (session == null) return 0;
    if (session.status == 'completed' || session.status == 'revealed') {
      return 1;
    }

    final puzzle = await puzzleDao.getPuzzle(puzzleId);
    if (puzzle == null) return 0;

    final progressRows = await sessionDao.loadCellProgress(session.id);
    final progress = _progressGridFromRows(
      width: puzzle.width,
      height: puzzle.height,
      rows: progressRows,
    );

    return ClueProgressCalculator.lockedClueCompletionFraction(
      puzzle: puzzle,
      progress: progress,
    );
  }

  Grid<CellProgress> _progressGridFromRows({
    required int width,
    required int height,
    required List<CellProgressRow> rows,
  }) {
    final rowsByCell = {
      for (final row in rows) (row.row, row.col): row,
    };
    return Grid<CellProgress>.generate(width, height, (row, col) {
      final progressRow = rowsByCell[(row, col)];
      if (progressRow == null) return CellProgress.blank;
      return CellProgress(
        letter: progressRow.guess ?? '',
        state: _cellStateFromDb(progressRow.state),
        isPencil: progressRow.isPencil,
      );
    });
  }

  CellState _cellStateFromDb(String value) {
    for (final state in CellState.values) {
      if (state.name == value) return state;
    }
    return CellState.empty;
  }
}
