import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_source.dart';

/// Community source candidate for Crosshare's daily mini.
///
/// Crosshare's application code is AGPL-3.0, but hosted puzzle-content rights
/// still need source-specific review before Crosscue fetches or caches puzzles.
class CrosshareSource implements PuzzleSource {
  const CrosshareSource();

  static const homepage = 'https://crosshare.org';
  static const githubUrl = 'https://github.com/crosshare-org/crosshare';
  static const dailyMiniApiUrl = 'https://crosshare.org/api/dailymini';

  @override
  String get id => 'crosshare_daily_mini';

  @override
  String get displayName => 'Crosshare Daily Mini';

  @override
  LicenseStatus get licenseStatus => LicenseStatus.needsReview;

  @override
  String? get licenseUrl => githubUrl;

  @override
  String? get permissionContact => homepage;

  @override
  String get cachePolicy =>
      'Visible candidate only; puzzle fetching and caching remain disabled until content rights are reviewed.';

  @override
  String? get lastLegalReviewAt => '2026-05-06';

  @override
  String? get reviewNotes =>
      'Crosshare code is AGPL-3.0. Hosted crossword content and API cache rights still need review.';

  @override
  bool get enabled => true;

  @override
  bool get attributionRequired => true;

  @override
  bool get commercialUseAllowed => false;

  @override
  bool get rawPayloadRetention => false;
}
