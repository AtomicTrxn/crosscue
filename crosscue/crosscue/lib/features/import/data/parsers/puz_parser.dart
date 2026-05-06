import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../../core/utils/result.dart';
import '../../../solve/domain/models/clue.dart';
import '../../../solve/domain/models/enums.dart';
import '../../../solve/domain/models/grid.dart';
import '../../../solve/domain/models/puzzle.dart';
import '../../../../core/domain/models/puzzle_metadata.dart';
import '../../../solve/domain/models/solution_cell.dart';
import '../../domain/models/parse_error.dart';
import '../../domain/repositories/puzzle_parser.dart';

/// Parses Across Lite .puz binary files.
///
/// Spec references:
///   https://code.google.com/archive/p/puz/wikis/FileFormat.wiki
class PuzParser implements PuzzleParser {
  const PuzParser();

  static const _magic = 'ACROSS&DOWN\x00';
  static const _magicOffset = 0x02;
  static const _widthOffset = 0x2C;
  static const _heightOffset = 0x2D;
  static const _numCluesOffset = 0x2E;
  static const _scrambleOffset = 0x32;
  static const _gridOffset = 0x34;

  /// Maximum accepted file size (5 MiB).  Real .puz files are ≤ 100 KB.
  static const _maxBytes = 5 * 1024 * 1024;

  /// GEXT flag bit indicating a circled cell (standard .puz spec).
  static const _gextCircledBit = 0x10;

  // Extension block tags
  static const _extGrbs = 'GRBS';
  static const _extRtbl = 'RTBL';
  static const _extGext = 'GEXT';

  @override
  bool canParse(Uint8List bytes) {
    if (bytes.length < _gridOffset) return false;
    final magic = latin1.decode(bytes.sublist(_magicOffset, _magicOffset + 12));
    return magic == _magic;
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
    if (!canParse(bytes)) return const Err(ParseError.invalidFormat);

    // --- header fields ---
    final width = bytes[_widthOffset];
    final height = bytes[_heightOffset];
    if (width == 0 || height == 0) return const Err(ParseError.missingData);

    final numClues = _readUint16LE(bytes, _numCluesOffset);
    final scramble = _readUint16LE(bytes, _scrambleOffset);
    if (scramble != 0) return const Err(ParseError.unsupportedFormat);

    final cellCount = width * height;
    if (bytes.length < _gridOffset + cellCount * 2) {
      return const Err(ParseError.missingData);
    }

    // --- solution grid ---
    final solutionBytes = bytes.sublist(_gridOffset, _gridOffset + cellCount);

    // --- player grid (skip — we don't need it for import) ---
    // bytes[_gridOffset + cellCount .. _gridOffset + cellCount*2]

    // --- strings section ---
    int cursor = _gridOffset + cellCount * 2;

    String readString() {
      final end = bytes.indexOf(0, cursor);
      if (end == -1) return '';
      final s = latin1.decode(bytes.sublist(cursor, end));
      cursor = end + 1;
      return s;
    }

    final title = readString();
    final author = readString();
    final copyright = readString();
    final clueTexts = [for (var i = 0; i < numClues; i++) readString()];
    final notes = readString();

    // --- extension blocks (GRBS, RTBL, GEXT) ---
    final rebusGrid = <int, int>{}; // cellIndex → rebus slot (1-based)
    final rebusTable = <int, String>{}; // slot → solution string
    final gextFlags = <int, int>{}; // cellIndex → flags byte

    while (cursor + 8 <= bytes.length) {
      final tag = latin1.decode(bytes.sublist(cursor, cursor + 4));
      final dataLen = _readUint16LE(bytes, cursor + 4);
      // cursor + 6: checksum (2 bytes), skip
      final dataStart = cursor + 8;
      final dataEnd = dataStart + dataLen;
      if (dataEnd > bytes.length) break;

      if (tag == _extGrbs) {
        for (var i = 0; i < dataLen && i < cellCount; i++) {
          final v = bytes[dataStart + i];
          if (v != 0) rebusGrid[i] = v;
        }
      } else if (tag == _extRtbl) {
        // Format: "01:EST; 02:TION;" …
        final raw = latin1.decode(bytes.sublist(dataStart, dataEnd));
        for (final entry in raw.split(';')) {
          final trimmed = entry.trim();
          if (trimmed.isEmpty) continue;
          final colonIdx = trimmed.indexOf(':');
          if (colonIdx == -1) continue;
          final slot = int.tryParse(trimmed.substring(0, colonIdx).trim());
          if (slot == null) continue;
          rebusTable[slot] = trimmed.substring(colonIdx + 1);
        }
      } else if (tag == _extGext) {
        for (var i = 0; i < dataLen && i < cellCount; i++) {
          final v = bytes[dataStart + i];
          if (v != 0) gextFlags[i] = v;
        }
      }

      cursor = dataEnd + 1; // +1 for null terminator after data
    }

    // --- build solution grid ---
    final cells = <SolutionCell>[];
    for (var i = 0; i < cellCount; i++) {
      final b = solutionBytes[i];
      if (b == 0x2E) {
        // '.' — black cell
        cells.add(SolutionCell.black);
        continue;
      }
      final String solution;
      if (rebusGrid.containsKey(i)) {
        final slot = rebusGrid[i]!;
        solution = rebusTable[slot] ?? latin1.decode([b]);
      } else {
        solution = latin1.decode([b]);
      }
      final circled = (gextFlags[i] ?? 0) & _gextCircledBit != 0;
      cells.add(SolutionCell(
        isBlack: false,
        solution: solution,
        circled: circled,
      ));
    }

    final grid = Grid<SolutionCell>(
      width: width,
      height: height,
      cells: cells,
    );

    // --- assign clue numbers and build Clue objects ---
    final numberedGrid = _assignNumbers(grid);
    final clues = _buildClues(numberedGrid, clueTexts, width, height);

    // --- compute puzzle ID ---
    final canonicalJson = _canonicalJson(
      width: width,
      height: height,
      solution: solutionBytes,
      title: title,
    );
    final digest = sha256.convert(utf8.encode(canonicalJson)).toString();
    final id = 'local:${digest.substring(0, 16)}';

    final checksum = digest;

    final metadata = PuzzleMetadata(
      id: id,
      sourceId: 'local_import',
      title: title.isEmpty ? 'Untitled' : title,
      author: author,
      copyright: copyright,
      format: PuzzleFormat.puz,
      width: width,
      height: height,
      totalClues: clues.length,
      importedAt: DateTime.now().toUtc(),
      notes: notes.isEmpty ? null : notes,
      checksum: checksum,
    );

    return Ok(Puzzle(
      metadata: metadata,
      grid: numberedGrid,
      clues: clues,
      notes: notes,
    ));
  }

  // ---- helpers ----

  int _readUint16LE(Uint8List bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);

  /// Walks the grid and assigns clue numbers according to standard rules.
  Grid<SolutionCell> _assignNumbers(Grid<SolutionCell> grid) {
    int number = 1;
    final newCells = List<SolutionCell>.from(grid.cells);

    for (var r = 0; r < grid.height; r++) {
      for (var c = 0; c < grid.width; c++) {
        final cell = grid.cell(r, c);
        if (cell.isBlack) continue;

        final startsAcross = _startsAcross(grid, r, c);
        final startsDown = _startsDown(grid, r, c);

        if (startsAcross || startsDown) {
          final idx = r * grid.width + c;
          newCells[idx] = cell.copyWith(number: number);
          number++;
        }
      }
    }

    return Grid<SolutionCell>(
      width: grid.width,
      height: grid.height,
      cells: newCells,
    );
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

  List<Clue> _buildClues(
    Grid<SolutionCell> grid,
    List<String> texts,
    int width,
    int height,
  ) {
    // Collect numbered cells in order (across clues first per number, then down)
    final acrossStarts = <_ClueStart>[];
    final downStarts = <_ClueStart>[];

    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        final cell = grid.cell(r, c);
        if (cell.isBlack || cell.number == null) continue;

        if (_startsAcross(grid, r, c)) {
          acrossStarts.add(_ClueStart(cell.number!, r, c));
        }
        if (_startsDown(grid, r, c)) {
          downStarts.add(_ClueStart(cell.number!, r, c));
        }
      }
    }

    // .puz interleaves clues: all across/down per number in ascending order
    // (across before down for same number)
    final orderedStarts = <(Direction, _ClueStart)>[];
    int ai = 0, di = 0;
    while (ai < acrossStarts.length || di < downStarts.length) {
      final hasA = ai < acrossStarts.length;
      final hasD = di < downStarts.length;
      if (hasA && (!hasD || acrossStarts[ai].number <= downStarts[di].number)) {
        orderedStarts.add((Direction.across, acrossStarts[ai++]));
      } else {
        orderedStarts.add((Direction.down, downStarts[di++]));
      }
    }

    final clues = <Clue>[];
    for (var i = 0; i < orderedStarts.length && i < texts.length; i++) {
      final (dir, start) = orderedStarts[i];
      final length = _measureLength(grid, start.row, start.col, dir);
      clues.add(Clue(
        number: start.number,
        direction: dir,
        text: texts[i],
        startRow: start.row,
        startCol: start.col,
        length: length,
      ));
    }

    return clues;
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

  String _canonicalJson({
    required int width,
    required int height,
    required Uint8List solution,
    required String title,
  }) {
    // Deterministic key for deduplication — does NOT include mutable fields.
    return '{"w":$width,"h":$height,"s":"${base64.encode(solution)}","t":${jsonEncode(title)}}';
  }
}

class _ClueStart {
  final int number;
  final int row;
  final int col;
  _ClueStart(this.number, this.row, this.col);
}
