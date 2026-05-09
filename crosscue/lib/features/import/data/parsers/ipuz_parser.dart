import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_parser.dart';

/// Parses .ipuz JSON puzzle files (ipuz.org spec v2).
class IpuzParser implements PuzzleParser {
  const IpuzParser();

  /// Maximum accepted file size (5 MiB).
  static const _maxBytes = 5 * 1024 * 1024;

  static const _blackCell = '#';

  @override
  bool canParse(Uint8List bytes) {
    try {
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      if (!text.startsWith('{')) return false;
      final json = jsonDecode(text) as Map<String, dynamic>;
      final kind = json['kind'];
      if (kind is List) {
        return kind.any((k) => k.toString().contains('crossword'));
      }
      return kind.toString().contains('crossword');
    } catch (_) {
      return false;
    }
  }

  @override
  Result<Puzzle, ParseError> parse(Uint8List bytes) {
    try {
      return _doParse(bytes);
    } catch (e) {
      return const Err(ParseError.unknown);
    }
  }

  Result<Puzzle, ParseError> _doParse(Uint8List bytes) {
    if (bytes.length > _maxBytes) return const Err(ParseError.fileTooLarge);

    final String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      return const Err(ParseError.encodingError);
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return const Err(ParseError.invalidFormat);
    }

    // --- dimensions ---
    final dimensions = json['dimensions'] as Map<String, dynamic>?;
    if (dimensions == null) return const Err(ParseError.missingData);
    final width = (dimensions['width'] as num?)?.toInt();
    final height = (dimensions['height'] as num?)?.toInt();
    if (width == null || height == null || width <= 0 || height <= 0) {
      return const Err(ParseError.missingData);
    }

    // --- solution grid ---
    final solutionRaw = json['solution'] as List<dynamic>?;
    if (solutionRaw == null) return const Err(ParseError.missingData);
    if (solutionRaw.length != height) return const Err(ParseError.missingData);

    final cells = <SolutionCell>[];
    final solutionStrings = <String>[]; // for checksum

    for (var r = 0; r < height; r++) {
      final row = solutionRaw[r] as List<dynamic>;
      if (row.length != width) return const Err(ParseError.missingData);
      for (var c = 0; c < width; c++) {
        final val = row[c];
        if (val == _blackCell || val == null) {
          cells.add(SolutionCell.black);
          solutionStrings.add('#');
        } else if (val is Map) {
          // rebus: {"cell": "EST"} or {"value": 0, "cell": "EST"}
          final letter = (val['cell'] ?? val['value'] ?? '').toString();
          cells.add(SolutionCell(isBlack: false, solution: letter));
          solutionStrings.add(letter);
        } else {
          final letter = val.toString();
          cells.add(SolutionCell(isBlack: false, solution: letter));
          solutionStrings.add(letter);
        }
      }
    }

    // --- puzzle grid (for circle flags) ---
    final puzzleRaw = json['puzzle'] as List<dynamic>?;
    if (_containsBarredGridData(solutionRaw) ||
        (puzzleRaw != null && _containsBarredGridData(puzzleRaw))) {
      return const Err(ParseError.unsupportedFormat);
    }
    final numberedCells = <int, int>{}; // cellIndex → clue number
    final circledCells = <int>{};

    if (puzzleRaw != null) {
      for (var r = 0; r < height && r < puzzleRaw.length; r++) {
        final row = puzzleRaw[r] as List<dynamic>;
        for (var c = 0; c < width && c < row.length; c++) {
          final val = row[c];
          final idx = r * width + c;
          if (val is Map) {
            final cell = val['cell'];
            if (cell is int && cell > 0) numberedCells[idx] = cell;
            final style = val['style'] as Map<String, dynamic>?;
            if (style != null &&
                (style['shapebg'] == 'circle' || style['color'] == 'circle')) {
              circledCells.add(idx);
            }
          } else if (val is int && val > 0) {
            numberedCells[idx] = val;
          }
        }
      }
    }

    // --- assign numbers if not in puzzle grid ---
    final useComputedNumbers = numberedCells.isEmpty;
    final newCells = List<SolutionCell>.from(cells);

    if (useComputedNumbers) {
      int number = 1;
      final tempGrid = Grid<SolutionCell>(
        width: width,
        height: height,
        cells: newCells,
      );
      for (var r = 0; r < height; r++) {
        for (var c = 0; c < width; c++) {
          final cell = tempGrid.cell(r, c);
          if (cell.isBlack) continue;
          final sa = _startsAcross(tempGrid, r, c);
          final sd = _startsDown(tempGrid, r, c);
          if (sa || sd) {
            final idx = r * width + c;
            numberedCells[idx] = number;
            number++;
          }
        }
      }
    }

    // Apply numbers + circles to cells
    for (var i = 0; i < newCells.length; i++) {
      if (newCells[i].isBlack) continue;
      newCells[i] = newCells[i].copyWith(
        number: numberedCells[i],
        circled: circledCells.contains(i),
      );
    }

    final grid = Grid<SolutionCell>(
      width: width,
      height: height,
      cells: newCells,
    );

    // --- clues ---
    final cluesRaw = json['clues'] as Map<String, dynamic>?;
    if (cluesRaw == null) return const Err(ParseError.missingData);

    final clues = <Clue>[];
    _parseClueList(cluesRaw, 'Across', Direction.across, grid, clues);
    _parseClueList(cluesRaw, 'Down', Direction.down, grid, clues);

    // --- metadata ---
    final title =
        (json['title'] as String? ?? '').replaceAll(RegExp(r'<[^>]+>'), '');
    final author = (json['author'] as String? ?? '');
    final copyright = (json['copyright'] as String? ?? '');
    final notes = (json['intro'] as String? ?? '');
    final difficulty = json['difficulty'] as String?;

    final canonicalJson =
        '{"w":$width,"h":$height,"s":${jsonEncode(solutionStrings.join())},"t":${jsonEncode(title)}}';
    final digest = sha256.convert(utf8.encode(canonicalJson)).toString();
    final id = 'local:${digest.substring(0, 16)}';

    final metadata = PuzzleMetadata(
      id: id,
      sourceId: 'local_import',
      title: title.isEmpty ? 'Untitled' : title,
      author: author,
      copyright: copyright,
      format: PuzzleFormat.ipuz,
      width: width,
      height: height,
      totalClues: clues.length,
      importedAt: DateTime.now().toUtc(),
      notes: notes.isEmpty ? null : notes,
      checksum: digest,
      difficulty: difficulty,
    );

    return Ok(Puzzle(
      metadata: metadata,
      grid: grid,
      clues: clues,
      notes: notes,
    ));
  }

  void _parseClueList(
    Map<String, dynamic> cluesRaw,
    String key,
    Direction direction,
    Grid<SolutionCell> grid,
    List<Clue> out,
  ) {
    final list = cluesRaw[key] as List<dynamic>?;
    if (list == null) return;
    for (final item in list) {
      int? number;
      String text = '';
      if (item is List && item.length >= 2) {
        number = int.tryParse(item[0].toString());
        text = item[1].toString();
      } else if (item is Map) {
        number =
            int.tryParse((item['number'] ?? item['Number'] ?? '').toString());
        text = (item['clue'] ?? item['text'] ?? '').toString();
      }
      if (number == null) continue;

      // Find start position
      int? startRow, startCol;
      for (var r = 0; r < grid.height && startRow == null; r++) {
        for (var c = 0; c < grid.width && startRow == null; c++) {
          if (grid.cell(r, c).number == number) {
            startRow = r;
            startCol = c;
          }
        }
      }
      if (startRow == null) continue;

      final length = _measureLength(grid, startRow, startCol!, direction);
      if (length < 2) continue;

      out.add(Clue(
        number: number,
        direction: direction,
        text: text,
        startRow: startRow,
        startCol: startCol,
        length: length,
      ));
    }
  }

  int _measureLength(Grid<SolutionCell> grid, int r, int c, Direction dir) {
    int len = 0;
    while (grid.inBounds(r, c) && !grid.cell(r, c).isBlack) {
      len++;
      if (dir == Direction.across) {
        c++;
      } else {
        r++;
      }
    }
    return len;
  }

  bool _startsAcross(Grid<SolutionCell> grid, int r, int c) {
    if (grid.cell(r, c).isBlack) return false;
    final leftBlack = c == 0 || grid.cell(r, c - 1).isBlack;
    final hasRight = c + 1 < grid.width && !grid.cell(r, c + 1).isBlack;
    return leftBlack && hasRight;
  }

  bool _startsDown(Grid<SolutionCell> grid, int r, int c) {
    if (grid.cell(r, c).isBlack) return false;
    final topBlack = r == 0 || grid.cell(r - 1, c).isBlack;
    final hasBelow = r + 1 < grid.height && !grid.cell(r + 1, c).isBlack;
    return topBlack && hasBelow;
  }

  bool _containsBarredGridData(List<dynamic> rows) {
    for (final row in rows) {
      if (row is! List) continue;
      for (final cell in row) {
        if (cell is! Map) continue;
        if (_mapHasBarKey(cell)) return true;
        final style = cell['style'];
        if (style is Map && _mapHasBarKey(style)) return true;
      }
    }
    return false;
  }

  bool _mapHasBarKey(Map<dynamic, dynamic> map) {
    for (final entry in map.entries) {
      final key = entry.key.toString().toLowerCase();
      final value = entry.value.toString().toLowerCase();
      if (key == 'barred' ||
          key == 'bars' ||
          key.startsWith('barred') ||
          key.endsWith('bar') ||
          value == 'barred') {
        return true;
      }
    }
    return false;
  }
}
