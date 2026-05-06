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
