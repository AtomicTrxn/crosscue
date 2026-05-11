import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:crosscue/features/stats/domain/services/stats_export_service.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';

part 'stats_export_notifier.g.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class StatsExportState {
  const StatsExportState();
}

class StatsExportIdle extends StatsExportState {
  const StatsExportIdle();
}

class StatsExportBusy extends StatsExportState {
  const StatsExportBusy();
}

class StatsExportSuccess extends StatsExportState {
  const StatsExportSuccess(this.count);
  final int count;
}

class StatsExportFailure extends StatsExportState {
  const StatsExportFailure(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class StatsExportNotifier extends _$StatsExportNotifier {
  @override
  StatsExportState build() => const StatsExportIdle();

  // ── Export ─────────────────────────────────────────────────────────────────

  /// Generates the export JSON and shares it via the system share sheet.
  Future<void> export() async {
    state = const StatsExportBusy();

    // 1. Generate JSON bytes via domain service
    final service = ref.read(statsExportServiceProvider);
    final bytesResult = await service.generateExportBytes();
    if (bytesResult.isErr) {
      state = StatsExportFailure(_errorMessage(bytesResult.error));
      return;
    }

    // 2. Write to temp file, share via system sheet
    try {
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final stamp =
          '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}';
      final file = File('${dir.path}/crosscue-stats-$stamp.json');
      await file.writeAsBytes(bytesResult.value, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Crosscue stats export',
      );
    } catch (e) {
      state = StatsExportFailure('Could not share file: $e');
      return;
    }

    // Count is implied by a successful export (shares all records).
    state = const StatsExportSuccess(0);
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  /// Opens the file picker, reads the chosen file, and imports it.
  Future<void> import_() async {
    state = const StatsExportBusy();

    // 1. Pick file (CONVENTIONS.md: always FileType.any, validate client-side)
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
    } catch (e) {
      state = StatsExportFailure('Could not open file picker: $e');
      return;
    }

    final pickedFile = result?.files.single;
    if (pickedFile == null) {
      // User cancelled — return to idle without changing state.
      state = const StatsExportIdle();
      return;
    }

    // Validate extension client-side.
    final ext = pickedFile.extension?.toLowerCase() ?? '';
    if (ext != 'json') {
      state = const StatsExportFailure('Only .json files can be imported.');
      return;
    }

    // 2. Read bytes (prefer in-memory, fall back to file path on desktop).
    final Uint8List bytes;
    if (pickedFile.bytes != null) {
      bytes = pickedFile.bytes!;
    } else if (pickedFile.path != null) {
      try {
        bytes = await File(pickedFile.path!).readAsBytes();
      } catch (e) {
        state = StatsExportFailure('Could not read file: $e');
        return;
      }
    } else {
      state = const StatsExportFailure('File data unavailable.');
      return;
    }

    // 3. Import via domain service.
    final service = ref.read(statsExportServiceProvider);
    final importResult = await service.importFromBytes(bytes);
    if (importResult.isErr) {
      state = StatsExportFailure(_errorMessage(importResult.error));
      return;
    }

    ref.invalidate(statsDataProvider);
    state = StatsExportSuccess(importResult.value);
  }

  void reset() => state = const StatsExportIdle();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _errorMessage(ExportError error) => switch (error) {
        ExportFormatError(:final message) => message,
        ExportInvalidDataError(:final message) => message,
      };

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Thin wrapper to pass Uint8List through the notifier without directly
/// importing dart:typed_data in the function signature.
class Uint8ListWrapper {
  const Uint8ListWrapper(this.data);
  final List<int> data;
}
