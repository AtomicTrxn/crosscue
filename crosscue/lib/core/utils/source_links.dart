import 'package:crosscue/core/domain/models/puzzle_metadata.dart';

/// Per-puzzle source attribution + link derivation.
///
/// The Crosshare URL is derived from the stored [PuzzleMetadata.sourcePuzzleId]
/// rather than persisting a dedicated `sourceUrl` column — no DB migration is
/// needed (see issue #186). Crosshare redirects an ID-only crossword URL to the
/// canonical slugged puzzle page.
///
/// The source-id literals below are the canonical ids defined by
/// `CrosshareSource` / `LocalImportSource` in the import feature's data layer.
/// They are duplicated here as constants to avoid a `core/` -> `features/`
/// dependency inversion.
const String _crosshareSourceId = 'crosshare_daily_mini';
const String _localImportSourceId = 'local_import';

const String _crosshareCrosswordBase = 'https://crosshare.org/crosswords/';

/// The public Crosshare page for [m], or `null` when the puzzle has no
/// trustworthy source link (local imports, or a Crosshare row missing its
/// `sourcePuzzleId`). Callers gate the "Open on Crosshare" action on non-null.
Uri? crosshareUrlFor(PuzzleMetadata m) {
  if (m.sourceId != _crosshareSourceId) return null;
  final id = m.sourcePuzzleId?.trim();
  if (id == null || id.isEmpty) return null;
  return Uri.parse('$_crosshareCrosswordBase$id');
}

/// Human-readable source name (e.g. "Crosshare"), or `null` for local imports.
String? sourceNameFor(String sourceId) => switch (sourceId) {
      _localImportSourceId => null,
      _crosshareSourceId => 'Crosshare',
      _ => sourceId,
    };

/// Short "via <source>" label used in the solve app bar, or `null` for local
/// imports (which have no external source to attribute).
String? sourceLabelFor(String sourceId) {
  final name = sourceNameFor(sourceId);
  return name == null ? null : 'via $name';
}
