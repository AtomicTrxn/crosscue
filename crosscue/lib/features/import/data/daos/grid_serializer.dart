import 'dart:convert';

import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';

/// Converts a [Puzzle]'s grid to/from a JSON map for DB storage.
class GridSerializer {
  const GridSerializer._();

  static Map<String, dynamic> toJson(Puzzle puzzle) {
    final rows = <List<Map<String, dynamic>>>[];
    for (var r = 0; r < puzzle.height; r++) {
      final row = <Map<String, dynamic>>[];
      for (var c = 0; c < puzzle.width; c++) {
        final cell = puzzle.grid.cell(r, c);
        row.add({
          'black': cell.isBlack,
          'solution': cell.solution,
          if (cell.number != null) 'number': cell.number,
          if (cell.circled) 'circled': true,
        });
      }
      rows.add(row);
    }
    return {
      'width': puzzle.width,
      'height': puzzle.height,
      'cells': rows,
    };
  }

  static String encode(Puzzle puzzle) => jsonEncode(toJson(puzzle));

  static Grid<SolutionCell> fromJson(Map<String, dynamic> json) {
    final width = json['width'] as int;
    final height = json['height'] as int;
    final rowsRaw = json['cells'] as List<dynamic>;
    final cells = <SolutionCell>[];
    for (var r = 0; r < height; r++) {
      final row = rowsRaw[r] as List<dynamic>;
      for (var c = 0; c < width; c++) {
        final cell = row[c] as Map<String, dynamic>;
        if (cell['black'] == true) {
          cells.add(SolutionCell.black);
        } else {
          cells.add(
            SolutionCell(
              isBlack: false,
              solution: cell['solution'] as String? ?? '',
              number: cell['number'] as int?,
              circled: cell['circled'] == true,
            ),
          );
        }
      }
    }
    return Grid<SolutionCell>(width: width, height: height, cells: cells);
  }
}
