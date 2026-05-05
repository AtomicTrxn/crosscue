# Research Topic #14 — Puzzle File Format Parser Spec

Status: Resolved
Implementation Status: ✅ Implemented — Sprint 2 parsers plus Sprint 8 regression tests/fixtures; superseded by MODELS.md + source code
Owner: Claude

## Research Question

What is the exact field-by-field layout of `.puz` and `.ipuz` puzzle files, and how does each field map to the app's `Puzzle`, `SolutionCell`, `Clue`, and `PuzzleMetadata` domain models?

## Decision To Unblock

What must a developer implement to write a correct, safe `.puz` and `.ipuz` parser in pure Dart before touching any other import code?

## Recommendation

Implement two independent parser classes (`PuzParser` and `IpuzParser`) behind a shared `PuzzleParser` interface. Each returns a `Result<Puzzle, ParseError>` — never throws, never crashes on malformed input. Write the `.puz` parser first since it is the harder format; `.ipuz` follows naturally from the domain model. Add a small `.jpz` parser stub for Phase 2 but do not block Phase 1 on it.

---

## Shared Parser Interface

```dart
// lib/features/import/data/parsers/puzzle_parser.dart
abstract class PuzzleParser {
  /// Returns [Puzzle] on success or [ParseError] on any failure.
  /// Never throws — all exceptions must be caught internally.
  Result<Puzzle, ParseError> parse(Uint8List bytes, String filename);
}

enum ParseError {
  fileTooLarge,
  unsupportedFormat,
  invalidHeader,
  checksumMismatch,
  missingRequiredField,
  invalidDimensions,
  malformedClues,
  encodingError,
  unknown,
}
```

A `ParseError` enum is sufficient for Phase 1; include a `message` field if richer diagnostics are needed later. The UI shows a single friendly error regardless of the specific variant (security rule: never expose internal details to the user).

---

## Part 1: `.puz` Format (AcrossLite Binary)

### Overview

`.puz` is a binary format created by Literate Software Systems in the 1990s and used as the de facto standard by most US crossword publishers through the 2010s. The full spec is documented at [fileformat.info/format/puz/](http://www.fileformat.info/format/puz/corion.htm) and in the [puz file format wiki](https://github.com/century-arcade/xd/blob/master/doc/puz-file-format.md).

### File Layout

```
Offset  Length  Field
------  ------  -----
0x00    0x02    Checksum (CRC-16 of entire file except this field)
0x02    0x0C    Magic string: "ACROSS&DOWN\0" (12 bytes, null-terminated)
0x0E    0x02    Header checksum (CRC of header bytes 0x2C–0x33)
0x10    0x08    Magic checksum ("ICHEATED" XOR mask — see below)
0x18    0x04    Version string e.g. "1.3\0"
0x1C    0x02    Reserved (unknown, usually 0x0000)
0x1E    0x02    Scrambled checksum (0 if not scrambled)
0x20    0x0C    Reserved (12 bytes, usually zero)
0x2C    0x01    Width  (uint8)
0x2D    0x01    Height (uint8)
0x2E    0x02    Number of clues (uint16 LE)
0x30    0x02    Unknown bitmask (usually 0x0001)
0x32    0x02    Scrambled tag (0 = not scrambled, 4 = scrambled)
0x34    W*H     Solution grid (one byte per cell, ASCII; '.' = black square)
0x34+WH W*H     Player grid (same layout; '-' = empty, '.' = black)
After grids: null-terminated strings in order:
  Title
  Author
  Copyright
  Clues (one per clue, in order: all across by number, then all down by number)
  Notes
```

### Key Parsing Notes

**Encoding:** All strings are ISO-8859-1 (Latin-1). Convert to UTF-8 immediately on read using Dart's `latin1.decode()` from `dart:convert`. Do not pass raw bytes as Dart strings.

**Grid layout:** Cells are stored row-major, left-to-right, top-to-bottom. Cell at `(row, col)` is at index `row * width + col`. Black squares are ASCII `.` (0x2E). Player grid uses `-` (0x2D) for empty white squares.

**Clue ordering:** Clues are stored in a single flat array — all across clues in ascending number order, then all down clues in ascending number order. Clue numbers must be computed from the grid (see below), not read from the file — the file only stores clue text.

**Computing clue numbers:** A cell gets a clue number if:
- It is a white square, AND
- It starts an across word (is in column 0 OR the cell to its left is black) AND has at least 2 white cells to its right, OR
- It starts a down word (is in row 0 OR the cell above is black) AND has at least 2 white cells below.

Number cells sequentially left-to-right, top-to-bottom.

**Rebus (extension block `GRBS`):** After the main data, `.puz` files may contain extension blocks. Each block has:
```
4 bytes  Section title (e.g. "GRBS", "RTBL", "LTIM", "GEXT", "RUSR")
2 bytes  Data length (uint16 LE)
2 bytes  Checksum of data (uint16 LE)
N bytes  Data
1 byte   Null terminator
```

For rebus support:
- `GRBS`: grid rebus — one byte per cell; 0 = no rebus, >0 = index into RTBL
- `RTBL`: rebus table — semicolon-separated `index:string` entries e.g. `1:HEART;2:STAR;`
- `GEXT`: cell flags — bit 0x10 = circled cell

**CRC validation:** The standard CRC-16 uses polynomial 0x8005, initial value 0. For Phase 1, validate the file-level checksum and reject files that fail. Log the mismatch in crash reporting but show a generic parse error to the user. A failed checksum almost always means a truncated or corrupted file.

**Scrambled puzzles:** If the scrambled tag at 0x32 is non-zero, the solution is encrypted. Do not attempt to decrypt. Return `ParseError.unsupportedFormat` with a note that scrambled puzzles are not supported.

### `.puz` → Domain Model Mapping

| `.puz` field | Domain model field | Notes |
|---|---|---|
| `Width` | `Puzzle.grid.width` | uint8 |
| `Height` | `Puzzle.grid.height` | uint8 |
| `Title` (string) | `PuzzleMetadata.title` | Latin-1 → UTF-8 |
| `Author` (string) | `PuzzleMetadata.author` | Latin-1 → UTF-8 |
| `Copyright` (string) | `PuzzleMetadata.copyright` | Latin-1 → UTF-8 |
| `Notes` (string) | `PuzzleMetadata.notes` | May be empty |
| Solution grid `'.'` | `SolutionCell.isBlack = true` | |
| Solution grid letter | `SolutionCell.answer` | Single char; rebus overrides below |
| Computed clue number | `SolutionCell.clueNumber` | Computed from grid, not file |
| `GRBS` + `RTBL` | `SolutionCell.answer` (multi-char) | Rebus string from table |
| `GEXT` bit 0x10 | `SolutionCell.isCircled = true` | |
| Across clue text[n] | `Clue.text` where `direction=across` | |
| Down clue text[n] | `Clue.text` where `direction=down` | |
| File checksum | Validated; not stored in domain model | |

`PuzzleMetadata.publishDate`: `.puz` has no publish date field — derive from filename if it follows the `YYYY-MM-DD` convention (common for downloaded puzzles), otherwise leave null.

`PuzzleMetadata.sourceFormat`: `PuzzleFormat.puz`

### `.puz` Parser Pseudocode

```dart
Result<Puzzle, ParseError> parse(Uint8List bytes, String filename) {
  if (bytes.length > 5 * 1024 * 1024) return Err(ParseError.fileTooLarge);

  final buf = ByteData.sublistView(bytes);

  // Validate magic string at offset 0x02
  final magic = latin1.decode(bytes.sublist(0x02, 0x0E));
  if (magic != 'ACROSS&DOWN\x00') return Err(ParseError.invalidHeader);

  // Check scramble tag
  final scrambledTag = buf.getUint16(0x32, Endian.little);
  if (scrambledTag != 0) return Err(ParseError.unsupportedFormat);

  final width  = bytes[0x2C];
  final height = bytes[0x2D];
  if (width < 3 || width > 50 || height < 3 || height > 50) {
    return Err(ParseError.invalidDimensions);
  }

  final numClues = buf.getUint16(0x2E, Endian.little);
  final gridSize = width * height;

  // Validate file is long enough for grids
  if (bytes.length < 0x34 + 2 * gridSize) return Err(ParseError.invalidHeader);

  // Validate CRC
  if (!_validateChecksum(bytes)) return Err(ParseError.checksumMismatch);

  // Parse solution grid
  final solutionBytes = bytes.sublist(0x34, 0x34 + gridSize);

  // Parse string section (after both grids)
  final stringStart = 0x34 + 2 * gridSize;
  final strings = _readNullTerminatedStrings(bytes, stringStart);
  // strings[0]=title, [1]=author, [2]=copyright, [3..3+numClues-1]=clues, last=notes

  if (strings.length < 3 + numClues) return Err(ParseError.missingRequiredField);

  // Parse extension blocks for rebus/circles
  final extensions = _parseExtensions(bytes, stringStart + _stringsLength(strings));

  // Build domain model
  final cells = _buildGrid(solutionBytes, width, height, extensions);
  final clues = _assignClues(cells, width, height,
      strings.sublist(3, 3 + numClues), numClues);

  return Ok(Puzzle(
    id: _generateId(filename, bytes),
    meta: PuzzleMetadata(
      title: strings[0],
      author: strings[1],
      copyright: strings[2],
      notes: strings.length > 3 + numClues ? strings[3 + numClues] : null,
      publishDate: _parseDateFromFilename(filename),
      sourceId: 'local_import',
      sourceFormat: PuzzleFormat.puz,
    ),
    grid: Grid(cells: cells, width: width, height: height),
    acrossClues: clues.where((c) => c.direction == Direction.across).toList(),
    downClues:   clues.where((c) => c.direction == Direction.down).toList(),
  ));
}
```

---

## Part 2: `.ipuz` Format (JSON)

### Overview

`.ipuz` is an open JSON standard defined at [ipuz.org](http://www.ipuz.org). Version 2 is current. The full spec is at `http://www.ipuz.org/crossword`. It is Crosscue's canonical storage format — all imported puzzles are converted to `.ipuz`-style JSON in `puzzles.canonical_json`.

### File Layout (JSON keys)

```json
{
  "version": "http://ipuz.org/v2",
  "kind": ["http://ipuz.org/crossword#1"],
  "copyright": "© 2024 Constructor Name",
  "publisher": "Publisher Name",
  "title": "Puzzle Title",
  "author": "Constructor Name",
  "editor": "Editor Name",
  "date": "01/15/2024",
  "notes": "Optional notes",
  "dimensions": { "width": 15, "height": 15 },
  "puzzle": [
    [{"cell": 1}, {"cell": 0}, "#", ...],
    ...
  ],
  "solution": [
    ["A", "B", "#", ...],
    ...
  ],
  "clues": {
    "Across": [
      [1, "Clue text for 1-Across"],
      [5, "Clue text for 5-Across"]
    ],
    "Down": [
      [1, "Clue text for 1-Down"]
    ]
  },
  "zones": [],
  "styles": {}
}
```

### Key Parsing Notes

**Black squares:** `puzzle[row][col]` is `"#"` for black squares. Solution also uses `"#"`.

**Cell numbers:** `puzzle[row][col]` is either `"#"` (black), `0` (white, no number), or `{"cell": N}` (white, clue number N). Some implementations use bare integers instead of objects — handle both `int` and `Map<String, dynamic>`.

**Solution:** `solution[row][col]` is `"#"` for black, a single uppercase letter for normal cells, or a multi-character string for rebus cells. If `solution` is absent, the puzzle is unsolved/constructor-only — mark `SolutionCell.answer = null` for all cells.

**Date format:** `date` field uses `MM/DD/YYYY`. Parse with `DateFormat('MM/dd/yyyy')` from `intl`. If absent or malformed, leave `publishDate` null.

**Clue format:** `clues.Across` and `clues.Down` are arrays of `[number, text]` pairs. Some publishers use `{"number": N, "clue": "text"}` objects instead — handle both.

**Styles / zones:** Ignore for Phase 1. These define shading, special cell styles, and rebus zones not needed for standard solving.

### `.ipuz` → Domain Model Mapping

| `.ipuz` field | Domain model field | Notes |
|---|---|---|
| `dimensions.width` | `Puzzle.grid.width` | |
| `dimensions.height` | `Puzzle.grid.height` | |
| `title` | `PuzzleMetadata.title` | |
| `author` | `PuzzleMetadata.author` | |
| `copyright` | `PuzzleMetadata.copyright` | |
| `publisher` | `PuzzleMetadata.publisher` | |
| `editor` | `PuzzleMetadata.editor` | |
| `date` (MM/DD/YYYY) | `PuzzleMetadata.publishDate` | Parse with intl |
| `notes` | `PuzzleMetadata.notes` | |
| `puzzle[r][c] == "#"` | `SolutionCell.isBlack = true` | |
| `puzzle[r][c].cell` | `SolutionCell.clueNumber` | 0 = no number |
| `solution[r][c]` | `SolutionCell.answer` | Multi-char = rebus |
| `clues.Across[n]` | `Clue(direction: across, number: n, text: ...)` | |
| `clues.Down[n]` | `Clue(direction: down, number: n, text: ...)` | |

`PuzzleMetadata.sourceFormat`: `PuzzleFormat.ipuz`

### `.ipuz` Parser Pseudocode

```dart
Result<Puzzle, ParseError> parse(Uint8List bytes, String filename) {
  if (bytes.length > 5 * 1024 * 1024) return Err(ParseError.fileTooLarge);

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  } catch (_) {
    return Err(ParseError.invalidHeader);
  }

  final dims = json['dimensions'] as Map<String, dynamic>?;
  final width  = (dims?['width']  as num?)?.toInt();
  final height = (dims?['height'] as num?)?.toInt();
  if (width == null || height == null ||
      width < 3 || width > 50 || height < 3 || height > 50) {
    return Err(ParseError.invalidDimensions);
  }

  final puzzle   = json['puzzle']   as List<dynamic>?;
  final solution = json['solution'] as List<dynamic>?;
  final clues    = json['clues']    as Map<String, dynamic>?;

  if (puzzle == null || clues == null) return Err(ParseError.missingRequiredField);
  if (puzzle.length != height) return Err(ParseError.invalidDimensions);

  final cells = _buildGrid(puzzle, solution, width, height);
  final clueList = _parseClues(clues);
  if (clueList == null) return Err(ParseError.malformedClues);

  return Ok(Puzzle(
    id: _generateId(filename, bytes),
    meta: _parseMeta(json, filename),  // _parseMeta must set sourceId: 'local_import'
    grid: Grid(cells: cells, width: width, height: height),
    acrossClues: clueList.where((c) => c.direction == Direction.across).toList(),
    downClues:   clueList.where((c) => c.direction == Direction.down).toList(),
  ));
}
```

---

## Puzzle ID Generation

Both parsers need a stable `Puzzle.id`. Use a SHA-256 checksum of the canonical puzzle content (solution grid + clue texts), not the raw bytes. This makes IDs stable across re-imports of the same puzzle from different sources or encodings.

```dart
String generateLocalPuzzleId(CanonicalPuzzle puzzle) {
  final canonical = jsonEncode({
    'width': puzzle.width,
    'height': puzzle.height,
    'solution': puzzle.solutionRows,
    'clues': puzzle.clues
        .map((clue) => {
              'direction': clue.direction.name,
              'number': clue.number,
              'text': clue.text.trim(),
              'answerLength': clue.answerLength,
            })
        .toList(),
  });
  final digest = sha256.convert(utf8.encode(canonical));
  return 'local:${digest.toString().substring(0, 16)}';
}
```

Use the `crypto` package (Apache 2.0, compatible) for SHA-256. Store the raw file SHA-256 separately as `puzzles.checksum` for exact duplicate-file detection; do not use raw bytes as the primary `Puzzle.id`.

---

## Error Handling Contract

| Condition | `ParseError` variant | User message |
|---|---|---|
| File > 5 MB | `fileTooLarge` | "This file is too large to import." |
| Wrong magic / not a valid file | `invalidHeader` | "This file could not be imported. It may be corrupted or in an unsupported format." |
| Scrambled `.puz` | `unsupportedFormat` | "Scrambled puzzles are not supported." |
| Width or height out of 3–50 range | `invalidDimensions` | "This file could not be imported. It may be corrupted or in an unsupported format." |
| Missing title / clues / grid | `missingRequiredField` | "This file could not be imported. It may be corrupted or in an unsupported format." |
| CRC mismatch | `checksumMismatch` | "This file could not be imported. It may be corrupted or in an unsupported format." |
| JSON decode failure | `invalidHeader` | "This file could not be imported. It may be corrupted or in an unsupported format." |

Never expose internal error details (stack traces, byte offsets) to the user. Remote crash/error reporting must use sanitized parser context only: error code, file extension, file size bucket, dimensions when safely parsed, and checksum prefix/hash metadata. Do not attach raw bytes, clue text, title/author/copyright fields, solution strings, imported files, or payload fragments.

---

## Test Fixture Requirements

Provide at least one fixture for each parser that has an explicit rights-cleared license:

| Fixture | Format | Source | Required coverage |
|---|---|---|---|
| `test_15x15_standard.puz` | `.puz` | Rights-cleared indie constructor file | Standard grid, no rebus, no circles |
| `test_15x15_rebus.puz` | `.puz` | Rights-cleared indie constructor file | GRBS + RTBL extension blocks |
| `test_15x15_circles.puz` | `.puz` | Rights-cleared indie constructor file | GEXT circles |
| `test_15x15_standard.ipuz` | `.ipuz` | Synthesised fixture (Creative Commons) | Standard grid |
| `test_15x15_rebus.ipuz` | `.ipuz` | Synthesised fixture | Multi-char solution cells |
| `test_corrupted.puz` | `.puz` | Synthesised | CRC fail → `checksumMismatch` |
| `test_truncated.puz` | `.puz` | Synthesised | Short file → `invalidHeader` |
| `test_scrambled.puz` | `.puz` | Synthesised | Scramble tag set → `unsupportedFormat` |
| `test_oversized.puz` | `.puz` | Synthesised | 6 MB file → `fileTooLarge` |

Fixtures live in `test/fixtures/puzzles/`.

---

## Additional Packages Required

| Package | License | Purpose |
|---------|---------|---------|
| `crypto` | Apache 2.0 | SHA-256 for puzzle ID generation |
| `intl` | BSD | `DateFormat` for `.ipuz` date parsing |

Both are already likely in the project; confirm in `pubspec.yaml`.

---

## Implementation Checklist

1. Add `crypto` to `pubspec.yaml` if not already present.
2. Create `lib/core/utils/result.dart` with `Result<T, E>`, `Ok<T,E>`, `Err<T,E>`.
3. Create `PuzzleParser` abstract class and `ParseError` enum.
4. Implement `PuzParser` — header validation, CRC check, grid parsing, string section, extension blocks.
5. Implement `IpuzParser` — JSON decode, dimension validation, grid and clue parsing.
6. Create test fixtures in `test/fixtures/puzzles/`.
7. Write unit tests for all fixtures and all `ParseError` variants.
8. Create `ImportRepositoryImpl` that: selects parser by file extension, calls `parse()`, maps `Puzzle` to Drift insert, handles `ParseError` → user-facing `ImportFailure`.

## Sources

Accessed 2026-05-01.

- [AcrossLite .puz format spec](https://github.com/century-arcade/xd/blob/master/doc/puz-file-format.md)
- [ipuz.org crossword spec](http://www.ipuz.org/crossword)
- [kotwords Kotlin .puz parser](https://github.com/jpd236/kotwords) — reference implementation; do not copy (Apache 2.0 compatible for reading, but write Dart from spec)
- [xword-dl Python parsers](https://github.com/thisisparker/xword-dl) — reference only
- Internal: [topic-02-drift-database-schema.md](topic-02-drift-database-schema.md)
- Internal: [architecture-design-review.md](../docs/archive/architecture-design-review.md)
