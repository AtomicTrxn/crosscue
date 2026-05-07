import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/import/data/daos/puzzle_dao.dart';
import 'package:crosscue/features/solve/data/daos/solve_session_dao.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/domain/repositories/archive_repository.dart';

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

    var whiteCells = 0;
    for (var row = 0; row < puzzle.height; row++) {
      for (var col = 0; col < puzzle.width; col++) {
        if (!puzzle.grid.cell(row, col).isBlack) whiteCells++;
      }
    }
    if (whiteCells == 0) return 0;

    final progressRows = await sessionDao.loadCellProgress(session.id);
    final filled = progressRows
        .where((row) => row.guess != null && row.guess!.isNotEmpty)
        .length;
    return (filled / whiteCells).clamp(0.0, 1.0);
  }
}
