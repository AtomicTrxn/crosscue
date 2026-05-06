/// One row in the Archive list — a puzzle combined with its latest session.
///
/// If no session has ever been started the [sessionId] is null and
/// [sessionStatus] defaults to 'not_started'.
class ArchiveEntry {
  const ArchiveEntry({
    required this.puzzleId,
    required this.title,
    required this.author,
    required this.width,
    required this.height,
    required this.importedAt,
    this.publishDate,
    this.sessionId,
    this.sessionStatus = 'not_started',
    this.completionType,
    this.elapsedMs,
    this.completedAt,
    this.lastPlayedAt,
  });

  final String puzzleId;
  final String title;
  final String author;
  final int width;
  final int height;

  /// When the puzzle was imported (createdAt from puzzles table).
  final DateTime importedAt;

  /// Puzzle publish date from metadata, if available.
  final DateTime? publishDate;

  /// Drift row id of the latest solve_session, or null if never started.
  final int? sessionId;

  /// DB status string: 'not_started' | 'in_progress' | 'completed' | 'revealed'.
  final String sessionStatus;

  /// DB completion_type string: 'clean' | 'checked' | 'hinted' | 'revealed'.
  final String? completionType;

  /// Active solve time (milliseconds) for the latest session.
  final int? elapsedMs;

  /// UTC timestamp when this session was completed, or null.
  final DateTime? completedAt;

  /// UTC timestamp when this puzzle was last interacted with.
  final DateTime? lastPlayedAt;

  // ---------------------------------------------------------------------------
  // Derived helpers
  // ---------------------------------------------------------------------------

  bool get isNotStarted =>
      sessionId == null || sessionStatus == 'not_started';
  bool get isInProgress => sessionStatus == 'in_progress';
  bool get isCompleted => sessionStatus == 'completed';
  bool get isRevealed => sessionStatus == 'revealed';

  /// True when this was a clean solve (no checks or reveals used).
  bool get isCleanSolve => completionType == 'clean';

  /// 'WW×HH' display label for grid dimensions.
  String get sizeLabel => '$width×$height';
}
