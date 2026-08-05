import 'dart:io';
import 'dart:typed_data';

import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_handler/share_handler.dart';

part 'shared_puzzle_import_service.g.dart';

/// Result of importing a file shared in from another app via the OS share
/// sheet (share_handler). Mirrors [ImportJobResult]'s three-way
/// success/duplicate/failure shape, adapted for a caller that wants to
/// navigate or show a snackbar rather than update `ImportState`:
///  - success carries a ready-to-use go_router path instead of the [Puzzle]
///    itself.
///  - failure carries the [ParseError] rather than a pre-formatted message —
///    the caller maps it via [ParseErrorMessage.userMessage], the same
///    mapping [ImportNotifier] uses for manual picker imports, so there is
///    one place that owns this copy.
sealed class SharedImportResult {
  const SharedImportResult();

  const factory SharedImportResult.success(String route) = SharedImportSuccess;
  const factory SharedImportResult.duplicate() = SharedImportDuplicate;
  const factory SharedImportResult.failure(ParseError error) =
      SharedImportFailure;
}

final class SharedImportSuccess extends SharedImportResult {
  const SharedImportSuccess(this.route);

  final String route;
}

final class SharedImportDuplicate extends SharedImportResult {
  const SharedImportDuplicate();
}

final class SharedImportFailure extends SharedImportResult {
  const SharedImportFailure(this.error);

  final ParseError error;
}

/// Imports a puzzle file that arrived via the OS share sheet
/// (`share_handler`'s [SharedAttachment]), reusing the existing import
/// pipeline ([ImportRepository.importBytes]).
///
/// The extension-based check in [importAttachment] is a cheap early-out
/// only, **not** the source of truth for what counts as a puzzle file —
/// `ImportRepositoryImpl` already content-sniffs via `PuzParser`/`IpuzParser`
/// magic-byte checks and returns `JobFailure(ParseError.invalidFormat)` for
/// anything unrecognised. The check here exists purely to skip obviously
/// irrelevant shares (a photo, a PDF) without reading their bytes; a valid
/// puzzle file that happens to arrive extension-less is *not* rejected by
/// it — it falls through to the real content-sniffing.
class SharedPuzzleImportService {
  SharedPuzzleImportService({required ImportRepository importRepository})
      : _importRepository = importRepository;

  final ImportRepository _importRepository;

  /// Sanity cap on the shared file's size. Puzzle files are always small
  /// (a few hundred KB at most); anything bigger is obviously not one, and
  /// this avoids reading a large unrelated file fully into memory.
  static const maxAttachmentBytes = 5 * 1024 * 1024;

  /// File extensions this cheap pre-filter recognises as puzzle files.
  static const _puzzleExtensions = {'puz', 'ipuz'};

  /// Normalizes [SharedAttachment.path]. On iOS, `share_handler` hands back
  /// an absolute `file://`-prefixed, percent-decoded-by-`Uri.decodeFull`
  /// string; on Android it's already a plain filesystem path. See Phase 1
  /// findings §1 for the verified source of this asymmetry.
  String normalizePath(String path) {
    if (path.startsWith('file://')) {
      return Uri.parse(path).toFilePath();
    }
    return path;
  }

  Future<SharedImportResult> importAttachment(
    SharedAttachment attachment,
  ) async {
    final path = normalizePath(attachment.path);
    final ext = _extensionOf(path);
    // Cheap early-out: an explicit, obviously-non-puzzle extension (e.g.
    // .jpg, .pdf) skips a doomed read+parse round trip. Extension-less
    // shares (ext == null) fall through to the real content-sniffing below.
    if (ext != null && !_puzzleExtensions.contains(ext)) {
      return const SharedImportResult.failure(ParseError.invalidFormat);
    }

    final file = File(path);
    final Uint8List bytes;
    try {
      final length = await file.length();
      if (length > maxAttachmentBytes) {
        return const SharedImportResult.failure(ParseError.fileTooLarge);
      }
      bytes = await file.readAsBytes();
    } on Object {
      // Missing/unreadable file (e.g. the plugin's temp copy was already
      // cleaned up) — not a parse error, but reuse the generic mapping so
      // the caller doesn't need a second error path.
      return const SharedImportResult.failure(ParseError.unknown);
    }

    final result = await _importRepository.importBytes(bytes);
    return switch (result) {
      JobSuccess(:final puzzle) =>
        SharedImportResult.success(Routes.solveFor(puzzle.id)),
      JobDuplicate() => const SharedImportResult.duplicate(),
      JobFailure(:final error) => SharedImportResult.failure(error),
    };
  }

  String? _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return null;
    return path.substring(dot + 1).toLowerCase();
  }
}

@Riverpod(keepAlive: true)
SharedPuzzleImportService sharedPuzzleImportService(Ref ref) {
  return SharedPuzzleImportService(
    importRepository: ref.watch(importRepositoryProvider),
  );
}
