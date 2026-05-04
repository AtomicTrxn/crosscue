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

  /// Something unexpected happened during parsing.
  unknown,
}
