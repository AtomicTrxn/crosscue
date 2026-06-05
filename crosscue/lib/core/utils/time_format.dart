/// Shared time-formatting utility.
///
/// Converts a duration in milliseconds to a human-readable string:
///   - Under an hour: "M:SS" (e.g. "4:07")
///   - One hour or more: "H:MM:SS" (e.g. "1:23:45")
String formatMs(int ms) {
  final total = ms ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a puzzle publish date as the source-calendar date.
///
/// Crosshare daily minis roll over by UTC date and are stored as midnight UTC.
/// Drift may hydrate that timestamp as a local `DateTime`; formatting that
/// directly would show the previous day west of UTC. Treat publish dates as
/// date-only values by formatting their UTC calendar components.
String formatPuzzlePublishDateShort(DateTime date) {
  final d = date.toUtc();
  return '${_weekdaysShort[d.weekday - 1]} ${_monthsShort[d.month - 1]} ${d.day}';
}

/// Longer source-calendar publish-date label used in archive rows.
String formatPuzzlePublishDateLong(DateTime date) {
  final d = date.toUtc();
  return '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';
}
