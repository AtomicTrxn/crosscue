import '../../../../core/database/app_database.dart';
import '../../../import/data/daos/puzzle_dao.dart';
import '../../../solve/data/daos/solve_session_dao.dart';
import '../../../solve/domain/models/puzzle_metadata.dart';
import '../../domain/models/archive_entry.dart';

/// Provides the Archive screen's data by combining [PuzzleDao] metadata with
/// the latest [SolveSessionRow] for each puzzle.
///
/// Uses an N+1 pattern (one latestSession query per puzzle) which is
/// acceptable for Phase 1 (import-only, typically <100 puzzles).
class ArchiveRepositoryImpl {
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
  Future<List<ArchiveEntry>> getArchiveEntries() async {
    final allPuzzles = await puzzleDao.getAllMetadata();
    final entries = <ArchiveEntry>[];

    for (final puzzle in allPuzzles) {
      final session = await sessionDao.getLatestSession(puzzle.id);
      entries.add(_buildEntry(puzzle, session));
    }

    return entries;
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Deletes [puzzleId] and all dependent rows (clues, sessions, cell_progress)
  /// via the cascade rule defined in the DB schema.
  Future<void> deletePuzzle(String puzzleId) =>
      puzzleDao.deletePuzzle(puzzleId);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  ArchiveEntry _buildEntry(PuzzleMetadata puzzle, SolveSessionRow? session) {
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
    );
  }
}
