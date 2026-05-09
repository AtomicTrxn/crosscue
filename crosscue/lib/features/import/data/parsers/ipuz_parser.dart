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
///
/// Compatibility notes:
///   - Clue direction keys: case-insensitive (`Across`, `across`, `ACROSS`).
///   - Block cells: `'#'`, `null`, and numeric `0` in solution rows.
///   - Map solution cells: prefers string-typed `cell`, `answer`, or `solution`
///     fields; numeric `value` is treated as numbering metadata, not an answer.
///   - Clue objects: accepts `[number, text]` arrays, `{number, clue}` objects,
///     and `{number, text}` objects. Clue text has simple HTML tags stripped.
///   - Circles: recognizes `style.shapebg`, `style.color`, `style.shape` == `'circle'`
///     and cell-level `circle: true`.
///   - Publish date: parses `YYYY-MM-DD` and `MM/DD/YYYY`; invalid dates become null.
///   - Barred grids: rejected as unsupported (cell-side bar keys detected in
///     `style` map). Full barred support requires a future `SolutionCell` boundary
///     model; see SPRINTS.md.
///   - Defensive shape validation: malformed JSON structures return structured
///     `ParseError` values rather than crashing to `ParseError.unknown`.
class IpuzParser implements PuzzleParser {
  const IpuzParser();

  /// Maximum accepted file size (5 MiB).
  static const _maxBytes = 5 * 1024 * 1024;

  static const _blackCell = '#';

  // Simple HTML tag/entity stripper for clue text.
  static final _htmlTagRe = RegExp(r'<[^>]+>');
  static final _htmlEntityRe = RegExp(r'&[a-zA-Z]+;|&#[0-9]+;');
  static const _htmlEntities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&nbsp;': ' ',
  };

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
    final dimensionsRaw = json['dimensions'];
    if (dimensionsRaw is! Map) return const Err(ParseError.missingData);
    final dimensions = dimensionsRaw as Map<String, dynamic>;
    final width = (dimensions['width'] as num?)?.toInt();
    final height = (dimensions['height'] as num?)?.toInt();
    if (width == null || height == null || width <= 0 || height <= 0) {
      return const Err(ParseError.missingData);
    }

    // --- solution grid ---
    final solutionRaw = json['solution'];
    if (solutionRaw is! List) return const Err(ParseError.missingData);
    if (solutionRaw.length != height) return const Err(ParseError.missingData);

    final cells = <SolutionCell>[];
    final solutionStrings = <String>[]; // for checksum

    for (var r = 0; r < height; r++) {
      final rowRaw = solutionRaw[r];
      if (rowRaw is! List) return const Err(ParseError.missingData);
      final row = rowRaw;
      if (row.length != width) return const Err(ParseError.missingData);
      for (var c = 0; c < width; c++) {
        final val = row[c];
        // Black cells: '#', null, or numeric 0
        if (val == _blackCell || val == null || val == 0) {
          cells.add(SolutionCell.black);
          solutionStrings.add('#');
        } else if (val is Map) {
          // Rebus / map cell: prefer string-typed answer fields;
          // treat numeric 'value' as numbering metadata, not an answer.
          final letter = _extractSolutionFromMap(val);
          cells.add(SolutionCell(isBlack: false, solution: letter));
          solutionStrings.add(letter);
        } else {
          final letter = val.toString();
          cells.add(SolutionCell(isBlack: false, solution: letter));
          solutionStrings.add(letter);
        }
      }
    }

    // --- puzzle grid (numbers + circles; barred grids rejected) ---
    final puzzleRaw = json['puzzle'];
    if (_containsBarredGridData(solutionRaw) ||
        (puzzleRaw is List && _containsBarredGridData(puzzleRaw))) {
      return const Err(ParseError.unsupportedFormat);
    }
    final numberedCells = <int, int>{}; // cellIndex → clue number
    final circledCells = <int>{};

    if (puzzleRaw is List) {
      for (var r = 0; r < height && r < puzzleRaw.length; r++) {
        final rowRaw = puzzleRaw[r];
        if (rowRaw is! List) continue;
        for (var c = 0; c < width && c < rowRaw.length; c++) {
          final val = rowRaw[c];
          final idx = r * width + c;
          if (val is Map) {
            final cell = val['cell'];
            if (cell is int && cell > 0) numberedCells[idx] = cell;
            // Cell-level circle flag
            if (val['circle'] == true) circledCells.add(idx);
            final style = val['style'];
            if (style is Map) {
              if (_isCircleStyle(style)) circledCells.add(idx);
            }
          } else if (val is int && val > 0) {
            numberedCells[idx] = val;
          }
          // '#' in puzzle grid = black cell; already handled in solution pass
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
    final cluesRaw = json['clues'];
    if (cluesRaw is! Map) return const Err(ParseError.missingData);

    final clues = <Clue>[];
    // Case-insensitive key lookup: find 'across' and 'down' variants
    final acrossKey = _findClueKey(cluesRaw as Map<String, dynamic>, 'across');
    final downKey = _findClueKey(cluesRaw, 'down');
    if (acrossKey != null) {
      _parseClueList(cluesRaw, acrossKey, Direction.across, grid, clues);
    }
    if (downKey != null) {
      _parseClueList(cluesRaw, downKey, Direction.down, grid, clues);
    }

    // --- metadata ---
    final title = _stripHtml(
        (json['title'] is String ? json['title'] as String : null) ?? '');
    final author =
        (json['author'] is String ? json['author'] as String : null) ?? '';
    final copyright =
        (json['copyright'] is String ? json['copyright'] as String : null) ??
            '';
    final difficulty =
        (json['difficulty'] is String ? json['difficulty'] as String : null);

    // Notes: prefer 'intro'; append publisher/editor if present
    final intro =
        (json['intro'] is String ? json['intro'] as String : null) ?? '';
    final publisher =
        (json['publisher'] is String ? json['publisher'] as String : null);
    final editor = (json['editor'] is String ? json['editor'] as String : null);
    final notesParts = <String>[
      if (intro.isNotEmpty) intro,
      if (publisher != null && publisher.isNotEmpty) 'Publisher: $publisher',
      if (editor != null && editor.isNotEmpty) 'Editor: $editor',
    ];
    final notes = notesParts.join('\n');

    // Publish date: try ISO YYYY-MM-DD, then US MM/DD/YYYY
    final dateStr =
        (json['date'] is String ? json['date'] as String : null) ?? '';
    final publishDate = _parseDate(dateStr);

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
      publishDate: publishDate,
    );

    return Ok(Puzzle(
      metadata: metadata,
      grid: grid,
      clues: clues,
      notes: notes,
    ));
  }

  // ---- helpers ----

  /// Finds the first key in [cluesRaw] whose lowercase form equals [target].
  String? _findClueKey(Map<String, dynamic> cluesRaw, String target) {
    for (final key in cluesRaw.keys) {
      if (key.toLowerCase() == target) return key;
    }
    return null;
  }

  /// Extracts a string answer from a map-valued solution cell.
  ///
  /// Prefers `cell`, `answer`, or `solution` if they are non-empty strings.
  /// Treats numeric `value` as numbering/style metadata and ignores it.
  String _extractSolutionFromMap(Map<dynamic, dynamic> val) {
    for (final key in ['cell', 'answer', 'solution']) {
      final v = val[key];
      if (v is String && v.isNotEmpty) return v;
    }
    // Fall back to 'value' only if it's a non-empty string
    final value = val['value'];
    if (value is String && value.isNotEmpty) return value;
    return '';
  }

  /// Returns true if the style map indicates a circle cell.
  bool _isCircleStyle(Map<dynamic, dynamic> style) {
    return style['shapebg'] == 'circle' ||
        style['color'] == 'circle' ||
        style['shape'] == 'circle';
  }

  /// Strips simple HTML tags and decodes common HTML entities from [text].
  String _stripHtml(String text) {
    var result = text.replaceAll(_htmlTagRe, '');
    result = result.replaceAllMapped(_htmlEntityRe, (m) {
      return _htmlEntities[m.group(0)] ?? m.group(0)!;
    });
    return result;
  }

  /// Parses a date string into a [DateTime].
  ///
  /// Accepts ISO `YYYY-MM-DD` and US `MM/DD/YYYY`. Returns null for
  /// unrecognized or invalid formats rather than failing the import.
  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    // ISO: YYYY-MM-DD
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final isoMatch = iso.firstMatch(raw);
    if (isoMatch != null) {
      return DateTime.tryParse(raw);
    }
    // US: MM/DD/YYYY
    final us = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final usMatch = us.firstMatch(raw);
    if (usMatch != null) {
      final y = int.parse(usMatch.group(3)!);
      final m = int.parse(usMatch.group(1)!);
      final d = int.parse(usMatch.group(2)!);
      try {
        return DateTime(y, m, d);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _parseClueList(
    Map<String, dynamic> cluesRaw,
    String key,
    Direction direction,
    Grid<SolutionCell> grid,
    List<Clue> out,
  ) {
    final listRaw = cluesRaw[key];
    if (listRaw is! List) return;
    for (final item in listRaw) {
      int? number;
      String text = '';
      if (item is List && item.length >= 2) {
        number = int.tryParse(item[0].toString());
        text = item[1].toString();
      } else if (item is Map) {
        // Accept 'number', 'Number', or 'label' for the clue number field
        final numRaw = item['number'] ?? item['Number'] ?? item['label'];
        number = int.tryParse((numRaw ?? '').toString());
        text = (item['clue'] ?? item['text'] ?? item['hint'] ?? '').toString();
      }
      if (number == null) continue;

      // Strip HTML from clue text
      text = _stripHtml(text);

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

  /// Returns true if the grid data contains cell-side bar keys, indicating a
  /// barred grid that Crosscue does not yet support.
  ///
  /// Known bar keys: `barred`, `bars`, any key starting with `barred` or
  /// ending with `bar`, or a value of `'barred'`. Full barred-grid support
  /// requires a future `SolutionCell` boundary model (see SPRINTS.md).
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
