/// Canonical size classifier for crossword puzzles.
///
/// Centralizes the width × height → bucket mapping that personal-best
/// tracking, the small-keyboard layout, and stats-screen labeling all
/// depend on. Adding a new bucket happens here and propagates through the
/// app — no scattered `width == 15 && height == 15` checks.
enum PuzzleSizeBucket {
  /// width ≤ 7 AND height ≤ 7 — daily mini.
  mini,

  /// 15 × 15 — standard weekday crossword.
  standard,

  /// 21 × 21 — Sunday-size crossword.
  large,

  /// Anything else — no personal best tracked, no size-specific UI.
  other;

  /// Returns the bucket for the given dimensions.
  ///
  /// Order matters: mini takes any small square up to 7 × 7, including
  /// the unlikely 5 × 7 or 6 × 7. Non-square 15 × N or 21 × N falls into
  /// [other] because personal bests are only tracked for the canonical
  /// square sizes.
  static PuzzleSizeBucket fromDimensions({
    required int width,
    required int height,
  }) {
    if (width <= 7 && height <= 7) return PuzzleSizeBucket.mini;
    if (width == 15 && height == 15) return PuzzleSizeBucket.standard;
    if (width == 21 && height == 21) return PuzzleSizeBucket.large;
    return PuzzleSizeBucket.other;
  }

  /// True when this bucket participates in personal-best tracking.
  bool get tracksPersonalBest => this != PuzzleSizeBucket.other;

  /// Short label used in stats UI (e.g. "Mini", "15×15"). Empty for
  /// [other] because untracked sizes are never displayed.
  String get displayLabel => switch (this) {
        PuzzleSizeBucket.mini => 'Mini',
        PuzzleSizeBucket.standard => '15×15',
        PuzzleSizeBucket.large => '21×21',
        PuzzleSizeBucket.other => '',
      };
}
