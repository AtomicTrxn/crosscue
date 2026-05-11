import 'dart:typed_data';

import 'package:crosscue/core/utils/result.dart';

// ---------------------------------------------------------------------------
// Error types
// ---------------------------------------------------------------------------

sealed class ExportError {
  const ExportError();
}

/// JSON serialisation failed or the export payload was malformed.
final class ExportFormatError extends ExportError {
  const ExportFormatError(this.message);
  final String message;
}

/// One or more records failed validation (skipped, not fatal).
final class ExportInvalidDataError extends ExportError {
  const ExportInvalidDataError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Domain interface
// ---------------------------------------------------------------------------

/// Abstract contract for stats export / import.
///
/// Declared in the domain layer so presentation providers depend only on
/// this interface, keeping the data layer replaceable and the service
/// mockable in tests.
///
/// Implementations must not touch the file system, the Share sheet, or any
/// Flutter UI concerns — those belong in the presentation notifier.
abstract interface class StatsExportService {
  /// Serialises all completed sessions to a UTF-8-encoded JSON byte array.
  ///
  /// Returns [Ok<Uint8List>] on success or [Err<ExportFormatError>] on failure.
  Future<Result<Uint8List, ExportError>> generateExportBytes();

  /// Parses and imports solve records from [bytes] (UTF-8 JSON).
  ///
  /// Returns [Ok<int>] with the number of newly imported records, or
  /// [Err<ExportError>] if the bytes cannot be decoded.
  Future<Result<int, ExportError>> importFromBytes(Uint8List bytes);
}
