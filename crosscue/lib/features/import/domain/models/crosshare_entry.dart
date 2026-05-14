/// A single Crosshare daily-mini entry, parsed from a month-archive page.
///
/// Each Crosshare month page exposes 28-31 of these via its embedded
/// `__NEXT_DATA__` JSON blob. Used by the data layer to enumerate available
/// puzzles before downloading any .puz bytes.
class CrosshareEntry {
  const CrosshareEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.authorName,
    required this.width,
    required this.height,
  });

  /// Crosshare's puzzle ID (e.g. `npa519boXnPf0byzTDJU`). Stable across time;
  /// used as the `.puz` endpoint key and as `sourcePuzzleId` once imported.
  final String id;

  /// The date this puzzle is scheduled to air as the daily mini. Day-of-month
  /// comes from the archive page; year/month are supplied by the caller since
  /// they are implicit in the archive URL.
  final DateTime date;

  final String title;
  final String authorName;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrosshareEntry &&
          other.id == id &&
          other.date == date &&
          other.title == title &&
          other.authorName == authorName &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(id, date, title, authorName, width, height);

  @override
  String toString() => 'CrosshareEntry(id: $id, date: $date, title: $title, '
      'authorName: $authorName, size: ${width}x$height)';
}
