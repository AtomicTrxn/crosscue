import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_parser.dart';
import 'package:crypto/crypto.dart';

/// Parses Across Lite .puz binary files.
///
/// Spec references:
///   https://code.google.com/archive/p/puz/wikis/FileFormat.wiki
///
/// Compatibility notes:
///   - GRBS/RTBL: accepts both standard 1-based slot keys and Crosshare-style
///     0-based keys (slot − 1 fallback).
///   - GEXT circles: accepts both bit 0x10 (standard) and bit 0x80 (Crosshare).
///   - Strings: tries UTF-8 first, falls back to Latin-1 on decode failure.
///   - Scramble: only bit 0x0004 indicates a locked solution; other bits are
///     non-scramble metadata and are tolerated.
///   - Hidden cells (byte 0x3A, ':') are not supported and cause rejection.
///   - App-supported grid dimensions: 2×2 – 25×25.
///   - Constructor notes are preserved verbatim (no boilerplate stripping).
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

  /// GEXT flag bit indicating a circled cell (standard Across Lite spec).
  static const _gextCircledBit = 0x10;

  /// GEXT flag bit indicating a circled cell (Crosshare / alternate writers).
  static const _gextCircledBit2 = 0x80;

  /// Scramble bitmask: only this bit locks the solution.
  /// Other nonzero bits in the scramble field are reserved/non-scramble metadata.
  static const _scrambledBit = 0x0004;

  /// Minimum supported grid dimension (both width and height).
  static const _minDimension = 2;

  /// Maximum supported grid dimension (both width and height).
  static const _maxDimension = 25;

  /// Solution byte for a hidden cell in some .puz writers (not supported).
  static const _hiddenCellByte = 0x3A; // ':'

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
  Result<Puzzle, ParseError> parse(
    Uint8List bytes, {
    String sourceId = 'local_import',
  }) {
    try {
      return _doParse(bytes, sourceId: sourceId);
    } catch (e) {
      return const Err(ParseError.unknown);
    }
  }

  Result<Puzzle, ParseError> _doParse(
    Uint8List bytes, {
    String sourceId = 'local_import',
  }) {
    if (bytes.length > _maxBytes) return const Err(ParseError.fileTooLarge);
    if (!canParse(bytes)) return const Err(ParseError.invalidFormat);

    // --- header fields ---
    final width = bytes[_widthOffset];
    final height = bytes[_heightOffset];

    // Zero dimensions indicate a truncated/corrupted file.
    if (width == 0 || height == 0) return const Err(ParseError.missingData);

    // Dimensions outside the app-supported range.
    if (width < _minDimension ||
        height < _minDimension ||
        width > _maxDimension ||
        height > _maxDimension) {
      return const Err(ParseError.unsupportedFormat);
    }

    final numClues = _readUint16LE(bytes, _numCluesOffset);

    // Only bit 0x0004 means "solution is scrambled/locked". Other bits are
    // reserved or used for non-scramble metadata by some writers.
    final scramble = _readUint16LE(bytes, _scrambleOffset);
    if (scramble & _scrambledBit != 0) {
      return const Err(ParseError.unsupportedFormat);
    }

    final cellCount = width * height;
    if (bytes.length < _gridOffset + cellCount * 2) {
      return const Err(ParseError.missingData);
    }

    // --- solution grid ---
    final solutionBytes = bytes.sublist(_gridOffset, _gridOffset + cellCount);

    // --- player grid (skip — we don't need it for import) ---
    // bytes[_gridOffset + cellCount .. _gridOffset + cellCount*2]

    // --- strings section ---
    // Try UTF-8 first (newer .puz writers); fall back to Latin-1 on failure.
    int cursor = _gridOffset + cellCount * 2;

    String readString() {
      final end = bytes.indexOf(0, cursor);
      if (end == -1) return '';
      final slice = bytes.sublist(cursor, end);
      cursor = end + 1;
      try {
        return utf8.decode(slice, allowMalformed: false);
      } catch (_) {
        return latin1.decode(slice);
      }
    }

    final title = readString();
    final author = readString();
    final copyright = readString();
    final clueTexts = [for (var i = 0; i < numClues; i++) readString()];
    final notes = readString();

    // --- extension blocks (GRBS, RTBL, GEXT) ---
    final rebusGrid = <int, int>{}; // cellIndex → rebus slot (1-based per spec)
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
        // Format: " 01:EST; 02:TION;" (standard) or " 00:EST;" (Crosshare).
        // Keys are parsed as integers and stored as-is; the cell-lookup below
        // tries both the slot value and slot−1 for compatibility.
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

      // Hidden cells (byte ':') are not yet supported by the domain model.
      // Reject rather than importing wrong answers.
      if (b == _hiddenCellByte) {
        return const Err(ParseError.unsupportedFormat);
      }

      final String solution;
      if (rebusGrid.containsKey(i)) {
        final slot = rebusGrid[i]!;
        // Standard .puz: GRBS stores 1-based slot, RTBL key matches exactly.
        // Crosshare-style: GRBS stores 1-based slot, RTBL key is slot−1 (0-based).
        solution =
            rebusTable[slot] ?? rebusTable[slot - 1] ?? latin1.decode([b]);
      } else {
        solution = latin1.decode([b]);
      }

      // Accept circle flag from either bit 0x10 (standard) or 0x80 (Crosshare).
      final circled =
          (gextFlags[i] ?? 0) & (_gextCircledBit | _gextCircledBit2) != 0;

      cells.add(
        SolutionCell(
          isBlack: false,
          solution: solution,
          circled: circled,
        ),
      );
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
    // Canonical string uses the resolved cell solutions (including rebus text)
    // so that puzzles differing only in rebus expansion get distinct IDs.
    // For non-rebus ASCII puzzles this produces the same base64 as the old
    // raw-byte approach, so existing IDs are preserved.
    final resolvedSolution =
        cells.map((c) => c.isBlack ? '.' : c.solution).join('');
    final canonicalJson = _canonicalJson(
      width: width,
      height: height,
      resolvedSolution: resolvedSolution,
      title: title,
    );
    final digest = sha256.convert(utf8.encode(canonicalJson)).toString();
    final id = 'local:${digest.substring(0, 16)}';

    final metadata = PuzzleMetadata(
      id: id,
      sourceId: sourceId,
      title: title.isEmpty ? 'Untitled' : title,
      author: author,
      copyright: copyright,
      format: PuzzleFormat.puz,
      width: width,
      height: height,
      importedAt: DateTime.now().toUtc(),
      notes: notes.isEmpty ? null : notes,
      checksum: digest,
    );

    return Ok(
      Puzzle(
        metadata: metadata,
        grid: numberedGrid,
        clues: clues,
        notes: notes,
      ),
    );
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

    // .puz interleaves clues: across before down for the same number
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
      clues.add(
        Clue(
          number: start.number,
          direction: dir,
          text: texts[i],
          startRow: start.row,
          startCol: start.col,
          length: length,
        ),
      );
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

  /// Builds the canonical JSON used for deduplication and ID generation.
  ///
  /// [resolvedSolution] is all cell solutions concatenated (black cells as '.'),
  /// including expanded rebus text. For non-rebus ASCII-only puzzles this
  /// produces identical base64 to the previous raw-byte approach.
  String _canonicalJson({
    required int width,
    required int height,
    required String resolvedSolution,
    required String title,
  }) {
    return '{"w":$width,"h":$height,"s":"${base64.encode(utf8.encode(resolvedSolution))}","t":${jsonEncode(title)}}';
  }
}

class _ClueStart {
  final int number;
  final int row;
  final int col;
  _ClueStart(this.number, this.row, this.col);
}
