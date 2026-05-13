import 'dart:convert';
import 'dart:io';

import 'package:crosscue/features/stats/data/daos/stats_dao.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StatsExportService {
  const StatsExportService({required this.dao});

  final StatsDao dao;

  Future<int> exportAndShare() async {
    final records = await dao.getExportRecords();
    final payload = records
        .map(
          (record) => {
            'completionType': record.completionType,
            'elapsedMs': record.elapsedMs,
            'solvedDateLocal': record.solvedDateLocal,
            'solvedTimezone': record.solvedTimezone,
            'width': record.width,
            'height': record.height,
            'puzzleTitle': record.puzzleTitle,
          },
        )
        .toList();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/crosscue-stats-export.json');
    await file
        .writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Crosscue stats export',
      ),
    );
    return records.length;
  }

  Future<int> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return 0;

    final bytes = file.bytes;
    final text = bytes != null
        ? utf8.decode(bytes)
        : await File(file.path!).readAsString();
    final decoded = jsonDecode(text);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON array.');
    }

    var imported = 0;
    for (final item in decoded) {
      if (item is! Map<String, Object?>) continue;
      final record = _recordFromJson(item);
      if (record == null) continue;
      final exists = await dao.hasCompletedRecord(
        puzzleTitle: record.puzzleTitle,
        solvedDateLocal: record.solvedDateLocal,
      );
      if (exists) continue;
      await dao.insertImportedRecord(record);
      imported++;
    }
    return imported;
  }

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
