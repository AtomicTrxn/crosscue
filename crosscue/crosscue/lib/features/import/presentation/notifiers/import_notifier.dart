import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/import_repository_impl.dart';
import '../../domain/models/parse_error.dart';
import '../providers/import_providers.dart';

part 'import_notifier.g.dart';

// ---------------------------------------------------------------------------
// UI state
// ---------------------------------------------------------------------------

sealed class ImportState {
  const ImportState();
}

class ImportIdle extends ImportState {
  const ImportIdle();
}

class ImportPicking extends ImportState {
  const ImportPicking();
}

class ImportParsing extends ImportState {
  const ImportParsing(this.fileName);
  final String fileName;
}

class ImportSuccess extends ImportState {
  const ImportSuccess(this.puzzleId, this.title);
  final String puzzleId;
  final String title;
}

class ImportDuplicate extends ImportState {
  const ImportDuplicate(this.fileName);
  final String fileName;
}

class ImportFailure extends ImportState {
  const ImportFailure(this.message);
  final String message;
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
      state = ImportFailure('Could not open file picker: $e');
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
        'Unsupported file type. Please choose a .puz or .ipuz file.',
      );
      return;
    }

    final bytes = file.bytes;
    if (bytes == null) {
      state = const ImportFailure('Could not read file data.');
      return;
    }

    state = ImportParsing(file.name);

    final repo = ref.read(importRepositoryProvider);
    final importResult = await repo.importBytes(Uint8List.fromList(bytes));

    switch (importResult) {
      case JobSuccess(:final puzzle):
        state = ImportSuccess(puzzle.id, puzzle.metadata.title);
      case JobDuplicate():
        state = ImportDuplicate(file.name);
      case JobFailure(:final error):
        state = ImportFailure(_errorMessage(error));
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
