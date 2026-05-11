import 'dart:typed_data';

import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'import_notifier.freezed.dart';
part 'import_notifier.g.dart';

// ---------------------------------------------------------------------------
// UI state
// ---------------------------------------------------------------------------

@freezed
class ImportState with _$ImportState {
  const factory ImportState.idle() = ImportIdle;
  const factory ImportState.picking() = ImportPicking;
  const factory ImportState.parsing({required String fileName}) = ImportParsing;
  const factory ImportState.success({
    required String puzzleId,
    required String title,
  }) = ImportSuccess;
  const factory ImportState.duplicate({required String fileName}) =
      ImportDuplicate;
  const factory ImportState.failure({required String message}) = ImportFailure;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class ImportNotifier extends _$ImportNotifier {
  @override
  ImportState build() => const ImportIdle();

  Future<void> pickAndImport() async {
    state = const ImportPicking();

    FilePickerResult? result;
    try {
      // FileType.any is required on Android because .puz/.ipuz/.jpz have no
      // registered MIME types — FileType.custom with those extensions produces
      // an empty MIME list and throws a PlatformException.
      result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
    } catch (e) {
      state = ImportFailure(message: 'Could not open file picker: $e');
      return;
    }

    if (result == null || result.files.isEmpty) {
      state = const ImportIdle();
      return;
    }

    final file = result.files.first;

    // Validate extension client-side since we can't filter server-side.
    final ext = file.extension?.toLowerCase() ?? '';
    if (!{'puz', 'ipuz', 'jpz'}.contains(ext)) {
      state = const ImportFailure(
        message: 'Unsupported file type. Please choose a .puz or .ipuz file.',
      );
      return;
    }

    final bytes = file.bytes;
    if (bytes == null) {
      state = const ImportFailure(message: 'Could not read file data.');
      return;
    }

    state = ImportParsing(fileName: file.name);

    final repo = ref.read(importRepositoryProvider);
    final importResult = await repo.importBytes(Uint8List.fromList(bytes));

    switch (importResult) {
      case JobSuccess(:final puzzle):
        state =
            ImportSuccess(puzzleId: puzzle.id, title: puzzle.metadata.title);
      case JobDuplicate():
        state = ImportDuplicate(fileName: file.name);
      case JobFailure(:final error):
        state = ImportFailure(message: _errorMessage(error));
    }
  }

  void reset() => state = const ImportIdle();

  String _errorMessage(ParseError error) {
    return switch (error) {
      ParseError.unsupportedFormat =>
        'This puzzle is scrambled or locked and cannot be imported.',
      ParseError.invalidFormat =>
        'Unrecognised puzzle format. Only .puz and .ipuz files are supported.',
      ParseError.missingData =>
        'The puzzle file appears to be incomplete or corrupted.',
      _ => 'Import failed. Please try a different file.',
    };
  }
}
