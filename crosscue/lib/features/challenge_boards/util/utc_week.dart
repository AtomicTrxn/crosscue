// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
/// Crosscue · UTC week boundaries.
///
/// Weekly boards run Monday–Sunday in UTC and reset Monday 00:00 UTC.
/// All boundary math is done in UTC so every player's week starts at the
/// same instant regardless of device timezone.
abstract final class UtcWeek {
  /// Monday 00:00:00 UTC of the week containing [now] (defaults to now).
  static DateTime weekStart([DateTime? now]) {
    final u = (now ?? DateTime.now()).toUtc();
    final daysFromMonday = (u.weekday - DateTime.monday) % 7; // Mon=0 … Sun=6
    final midnight = DateTime.utc(u.year, u.month, u.day);
    return midnight.subtract(Duration(days: daysFromMonday));
  }

  /// Next Monday 00:00:00 UTC (the reset instant).
  static DateTime nextReset([DateTime? now]) =>
      weekStart(now).add(const Duration(days: 7));

  static Duration untilReset([DateTime? now]) =>
      nextReset(now).difference((now ?? DateTime.now()).toUtc());

  /// "Resets in 2d 14h" / "Resets in 14h 03m" / "Resets in 12m".
  static String resetCountdownLabel([DateTime? now]) {
    final d = untilReset(now);
    if (d.inDays >= 1) return 'Resets in ${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) {
      return 'Resets in ${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
    }
    return 'Resets in ${d.inMinutes}m';
  }

  /// Eyebrow suffix shown on the weekly card. The full boundary, for clarity.
  static const String weekBoundaryLabel = 'This week · UTC';

  /// Verbose form for board detail freshness.
  static const String detailBoundaryLabel =
      'This week (UTC) · resets Mon 00:00';

  /// Absolute time included in accessibility labels (never timezone-relative).
  static const String accessibleReset = 'resets Monday 00:00 UTC';

  /// Lifetime basis line.
  static const String lifetimeBasis = 'Completed UTC weeks only';
}
