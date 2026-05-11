import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/stats/data/daos/stats_dao.dart';
import 'package:crosscue/features/stats/domain/services/stats_export_service.dart';

/// Data-layer implementation of [StatsExportService].
///
/// Responsibilities: JSON serialisation, record validation, DAO interaction.
/// No file system, Share sheet, or Flutter UI access — those live in the
/// presentation notifier.
class StatsExportServiceImpl implements StatsExportService {
  const StatsExportServiceImpl({required StatsDao dao}) : _dao = dao;

  final StatsDao _dao;

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  @override
  Future<Result<Uint8List, ExportError>> generateExportBytes() async {
    try {
      final records = await _dao.getExportRecords();
      final payload = records
          .map(
            (r) => {
              'completionType': r.completionType,
              'elapsedMs': r.elapsedMs,
              'solvedDateLocal': r.solvedDateLocal,
              'solvedTimezone': r.solvedTimezone,
              'width': r.width,
              'height': r.height,
              'puzzleTitle': r.puzzleTitle,
            },
          )
          .toList();

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      return Ok(Uint8List.fromList(utf8.encode(jsonStr)));
    } catch (e) {
      return Err(ExportFormatError('Failed to generate export: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  @override
  Future<Result<int, ExportError>> importFromBytes(Uint8List bytes) async {
    final String text;
    try {
      text = utf8.decode(bytes);
    } catch (e) {
      return Err(ExportFormatError('Could not decode file as UTF-8: $e'));
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (e) {
      return Err(ExportFormatError('Invalid JSON: $e'));
    }

    if (decoded is! List) {
      return const Err(ExportFormatError('Expected a JSON array'));
    }

    var imported = 0;
    for (final item in decoded) {
      if (item is! Map<String, Object?>) continue;
      final record = _recordFromJson(item);
      if (record == null) continue;
      final exists = await _dao.hasCompletedRecord(
        puzzleTitle: record.puzzleTitle,
        solvedDateLocal: record.solvedDateLocal,
      );
      if (exists) continue;
      await _dao.insertImportedRecord(record);
      imported++;
    }
    return Ok(imported);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  StatsExportRecord? _recordFromJson(Map<String, Object?> json) {
    final completionType = json['completionType'];
    final elapsedMs = json['elapsedMs'];
    final solvedDateLocal = json['solvedDateLocal'];
    final width = json['width'];
    final height = json['height'];
    final puzzleTitle = json['puzzleTitle'];

    if (completionType is! String ||
        elapsedMs is! num ||
        solvedDateLocal is! String ||
        width is! num ||
        height is! num ||
        puzzleTitle is! String) {
      return null;
    }
    if (solvedDateLocal.isEmpty || puzzleTitle.isEmpty) return null;

    final solvedTimezone = json['solvedTimezone'];
    return (
      completionType: completionType,
      elapsedMs: elapsedMs.round(),
      solvedDateLocal: solvedDateLocal,
      solvedTimezone: solvedTimezone is String ? solvedTimezone : null,
      width: width.round(),
      height: height.round(),
      puzzleTitle: puzzleTitle,
    );
  }
}
