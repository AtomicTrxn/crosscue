/// Structured errors returned by puzzle parsers.
enum ParseError {
  /// The bytes / JSON don't match the expected format at all.
  invalidFormat,

  /// The file is a valid .puz but the solution is scrambled (locked).
  unsupportedFormat,

  /// A required field (title, grid size, etc.) is missing or malformed.
  missingData,

  /// The file could not be decoded to text (encoding issue).
  encodingError,

  /// File exceeds the maximum permitted size (5 MB).
  fileTooLarge,

  /// File-level checksum does not match the content (truncated / corrupt).
  checksumMismatch,

  /// Something unexpected happened during parsing.
  unknown,
}

/// Human-readable copy for a [ParseError], shown to the user when an import
/// fails. Single source of truth for this mapping — reused by
/// [ImportNotifier] (manual file-picker imports) and
/// [SharedPuzzleImportService] (OS share-sheet imports) so the two entry
/// points never drift into showing different wording for the same error.
extension ParseErrorMessage on ParseError {
  String get userMessage => switch (this) {
        ParseError.unsupportedFormat =>
          'This puzzle is scrambled or locked and cannot be imported.',
        ParseError.invalidFormat =>
          'Unrecognised puzzle format. Only .puz and .ipuz files are supported.',
        ParseError.missingData =>
          'The puzzle file appears to be incomplete or corrupted.',
        _ => 'Import failed. Please try a different file.',
      };
}
