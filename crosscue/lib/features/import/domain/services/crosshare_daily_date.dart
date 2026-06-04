/// Crosshare's Daily Mini rolls over by UTC calendar date.
///
/// Keep this helper small and shared so the downloader, auto-download state,
/// and Today/Past Puzzles UI do not drift back to device-local dates.
DateTime crosshareUtcDate([DateTime? at]) {
  final utc = (at ?? DateTime.now()).toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

String crosshareUtcDateString([DateTime? at]) {
  final date = crosshareUtcDate(at);
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd';
}

bool isSameCrosshareUtcDate(DateTime a, DateTime b) {
  final aa = crosshareUtcDate(a);
  final bb = crosshareUtcDate(b);
  return aa.year == bb.year && aa.month == bb.month && aa.day == bb.day;
}
