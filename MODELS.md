# Domain Models Reference — Crosscue

All models live under `crosscue/lib/features/solve/domain/models/` unless noted.
Generated files (`.freezed.dart`, `.g.dart`) are never edited by hand.

---

## `Grid<T>` — `grid.dart`

Plain Dart class (NOT Freezed — Freezed's codegen cannot handle generic type parameters).

```dart
class Grid<T> {
  final int width;
  final int height;
  final List<T> cells;           // row-major: index = row * width + col

  T cell(int row, int col)
  Grid<T> withCell(int row, int col, T value)  // returns new Grid (immutable)
  Grid<R> map<R>(R Function(int row, int col, T cell) fn)
  bool inBounds(int row, int col)

  factory Grid.generate(int width, int height, T Function(int row, int col) fn)
}
```

Used as `Grid<SolutionCell>` (the answer grid) and `Grid<CellProgress>` (user progress).

---

## `SolutionCell` — `solution_cell.dart`

```dart
@freezed
abstract class SolutionCell with _$SolutionCell {
  const factory SolutionCell({
    @Default(false) bool isBlack,
    @Default('') String solution,   // single letter, or multi-letter for rebus
    int? number,                    // clue number, null if not a clue-start cell
    @Default(false) bool circled,
  }) = _SolutionCell;

  static const SolutionCell black = SolutionCell(isBlack: true);
}
```

`solution` is the canonical answer. For rebus cells it may be `'EST'`, `'TION'`, etc.
`number` is assigned by `PuzParser._assignNumbers()` using standard crossword rules.

---

## `CellProgress` — `cell_progress.dart`

```dart
@freezed
abstract class CellProgress with _$CellProgress {
  const factory CellProgress({
    @Default('') String letter,
    @Default(CellState.empty) CellState state,
    @Default(false) bool isPencil,
  }) = _CellProgress;

  static const CellProgress blank = CellProgress();
}
```

`letter` is always uppercase. `state` drives cell background color in the painter.
`isPencil` is stored for future pencil-mode; currently always `false`.

---

## `Clue` — `clue.dart`

```dart
@freezed
abstract class Clue with _$Clue {
  const factory Clue({
    required int number,
    required Direction direction,
    required String text,
    required int startRow,
    required int startCol,
    required int length,
  }) = _Clue;
}
```

`length` is the number of cells in the answer. The answer cells are:
- Across: `(startRow, startCol)` … `(startRow, startCol + length - 1)`
- Down:   `(startRow, startCol)` … `(startRow + length - 1, startCol)`

---

## `FocusPosition` — `focus_position.dart`

```dart
@freezed
abstract class FocusPosition with _$FocusPosition {
  const factory FocusPosition({
    required int row,
    required int col,
    required Direction direction,
  }) = _FocusPosition;
}
```

Stored in `SolveState.focus`. Direction toggles on repeated tap of same cell.

---

## `PuzzleMetadata` — `puzzle_metadata.dart`

```dart
@freezed
abstract class PuzzleMetadata with _$PuzzleMetadata {
  const factory PuzzleMetadata({
    required String id,           // 'local:' + 16-char SHA-256 prefix
    required String sourceId,     // FK to sources table, e.g. 'local_import'
    required String title,
    @Default('') String author,
    @Default('') String copyright,
    required PuzzleFormat format, // .puz | .ipuz | .jpz
    required int width,
    required int height,
    required int totalClues,
    required DateTime importedAt,
    String? notes,
    String? checksum,             // full SHA-256 hex string for duplicate detection
  }) = _PuzzleMetadata;
}
```

`id` format: `'local:' + sha256(canonicalJson).substring(0, 16)`.
`checksum` is the **full** SHA-256 — used for duplicate detection in the DAO.

---

## `Puzzle` — `puzzle.dart`

```dart
@freezed
abstract class Puzzle with _$Puzzle {
  const factory Puzzle({
    required PuzzleMetadata metadata,
    required Grid<SolutionCell> grid,
    required List<Clue> clues,
    @Default('') String notes,
  }) = _Puzzle;
}

// Convenience accessors (via extension or metadata delegation):
puzzle.id        // metadata.id
puzzle.width     // metadata.width
puzzle.height    // metadata.height
```

`grid` contains the full solution. Never stored in memory after the session ends —
the DB holds `canonicalJson` and the grid is reconstructed via `GridSerializer.fromJson`.

---

## `SolveState` — `solve/presentation/notifiers/solve_state.dart`

**Presentation layer only** — lives in `presentation/notifiers/`, not in `domain/`.
Plain immutable class (not Freezed — contains `Grid<T>`).

```dart
class SolveState {
  final Puzzle puzzle;
  final Grid<CellProgress> progress;
  final FocusPosition focus;
  final PuzzleStatus status;
  final int elapsedSeconds;
  final bool isPaused;

  // Derived (computed, not stored):
  Clue? get activeClue        // clue matching focus cell + direction
  Clue? get crossClue         // clue in the perpendicular direction
  List<(int,int)> get activeWordCells

  bool isFocused(int row, int col)
  bool isWordHighlighted(int row, int col)
  bool isCrossHighlighted(int row, int col)

  static bool cellInClue(int row, int col, Clue clue)  // public static for cross-file use

  SolveState copyWith({progress, focus, status, elapsedSeconds, isPaused})
}
```

---

## Enums — `enums.dart`

| Enum | Values | Used by |
|------|--------|---------|
| `Direction` | `across`, `down` | Clue, FocusPosition, SolveNotifier |
| `CellState` | `empty`, `filled`, `checkedCorrect`, `checkedIncorrect`, `revealed` | CellProgress, painter |
| `PuzzleStatus` | `unsolved`, `inProgress`, `solved`, `solvedWithHelp`, `revealed` | SolveState, SolveNotifier |
| `PuzzleFormat` | `puz`, `ipuz`, `jpz` | PuzzleMetadata, parsers |
| `EntryMode` | `normal`, `pencil`, `rebus` | Post-MVP |
| `SourceType` | `free`, `subscription`, `local` | SourcesTable |
| `LicenseStatus` | `userImport`, `explicitPermission`, `openLicense`, `needsReview`, `prohibited` | SourcesTable |
| `CompletionType` | `clean`, `checked`, `hinted`, `revealed` | SolveSessionsTable |

---

## DB ↔ Domain Mapping

| DB table | Domain type | Converted by |
|----------|-------------|-------------|
| `puzzles` row | `PuzzleMetadata` | `PuzzleDao._rowToMetadata()` |
| `puzzles.canonical_json` | `Grid<SolutionCell>` | `GridSerializer.fromJson()` |
| `clues` row | `Clue` | `PuzzleDao._clueRowToClue()` |
| `solve_sessions` row | `SolveState` fields | Sprint 4 — not yet implemented |
| `cell_progress` row | `CellProgress` | Sprint 4 — not yet implemented |

---

## Puzzle ID Format

```
local:<hex16>
│      └─ First 16 chars of SHA-256 of canonical JSON:
│          '{"w":<width>,"h":<height>,"s":"<base64-solution>","t":<json-title>}'
└─ Source prefix — 'local' for user-imported files
```

The full SHA-256 (64 hex chars) is stored separately as `checksum` for duplicate detection.
The `id` (16-char prefix) is the stable foreign key used across the DB and in routing.

---

## `ParseError` — `import/domain/models/parse_error.dart`

```dart
enum ParseError {
  invalidFormat,      // not a recognised format
  unsupportedFormat,  // scrambled / locked puzzle
  missingData,        // incomplete or corrupted file
  encodingError,      // character encoding failure
  unknown,            // catch-all for unexpected exceptions
}
```

---

## `ImportJobResult` — `import/data/repositories/import_repository_impl.dart`

Sealed class (prefixed `Job` to avoid collision with UI `ImportState`):

```dart
sealed class ImportJobResult { ... }
final class JobSuccess   extends ImportJobResult { final Puzzle puzzle; }
final class JobDuplicate extends ImportJobResult { }
final class JobFailure   extends ImportJobResult { final ParseError error; }
```

---

## `ImportState` — `import/presentation/notifiers/import_notifier.dart`

Freezed union (multi-factory → plain `class`, not `abstract class`):

```dart
@freezed
class ImportState with _$ImportState {
  const factory ImportState.idle()                          = ImportIdle;
  const factory ImportState.loading()                      = ImportLoading;
  const factory ImportState.success(PuzzleMetadata puzzle) = ImportSuccess;
  const factory ImportState.duplicate()                    = ImportDuplicate;
  const factory ImportState.failure(String message)        = ImportFailure;
}
```

`ImportNotifier` exposes `state` as `ImportState` and calls
`ref.invalidate(puzzleListProvider)` after a successful import so the home list
refreshes automatically.

---

## `Result<T, E>` — `core/utils/result.dart`

Lightweight result type used in parsers and repository methods to avoid
exception-based control flow:

```dart
sealed class Result<T, E> { ... }
final class Ok<T, E>  extends Result<T, E> { final T value; }
final class Err<T, E> extends Result<T, E> { final E error; }
```

Usage pattern:
```dart
// Returning a result:
return Ok(parsedPuzzle);
return Err(ParseError.invalidFormat);

// Consuming a result:
final result = await parser.parse(bytes);
switch (result) {
  case Ok(:final value): // use value
  case Err(:final error): // handle error
}
```

`PuzzleParser.parse()` returns `Result<Puzzle, ParseError>`.
`ImportRepositoryImpl.importBytes()` internally maps this to `ImportJobResult`.
