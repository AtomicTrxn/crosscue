# Domain Models Reference — Crosscue

> **Status:** Living. This file documents **semantics and invariants** — the
> things the code can't say about itself. Field lists and signatures live in
> the source files; when this doc and the code disagree on a *shape*, the code
> is right and this doc needs a smaller claim, not a bigger transcription.

Shared domain models live under `crosscue/lib/core/domain/models/`.
Solve-only models (`CellProgress`, `FocusPosition`) live under
`crosscue/lib/features/solve/domain/models/`.
Generated files (`.freezed.dart`, `.g.dart`) are never edited by hand.

---

## Core puzzle models

### `Grid<T>` — `core/domain/models/grid.dart`

Plain Dart class — **not** Freezed (codegen can't handle the generic
parameter; see CONVENTIONS.md). Invariants:

- Cells are stored row-major: `index = row * width + col`.
- Immutable: `withCell(r, c, v)` returns a **new** `Grid`; nothing mutates
  in place.
- Used as `Grid<SolutionCell>` (the answer grid) and `Grid<CellProgress>`
  (user progress).

### `SolutionCell` — `core/domain/models/solution_cell.dart`

One cell of the answer grid (`@freezed abstract class`).

- `solution` is the canonical answer: a single letter, or a multi-letter
  string for rebus cells (`'EST'`), or a `"/"`-delimited bidirectional pair
  (`'PB/AU'`).
- `number` is assigned by `PuzParser._assignNumbers()` using standard
  crossword rules; null for non-clue-start cells.
- `SolutionCell.black` is a `static const` sentinel — deliberately **not** a
  factory constructor (that would turn the class into a union; see
  CONVENTIONS.md).
- **`accepts(entered)` is the single acceptance rule** for all correctness
  checks (completion, check actions, clue correctness): exact match, first
  letter of a rebus, or either side of a bidirectional pair
  ([ADR-0010](docs/architecture/decisions/0010-rebus-entry-ux.md)). Never
  compare with string equality.

### `CellProgress` — `solve/domain/models/cell_progress.dart`

One cell of user progress (solve-only).

- `letter` is always uppercase; may be multi-letter for rebus entries (the
  DB stores it as-is inside the serialized progress grid).
- Verification states color the **letter**; reveal uses a distinct
  **background** — the painter owns that mapping (see ARCHITECTURE.md →
  Theme System).
- `isPencil` is stored for a future pencil mode; currently always `false`.
- `CellProgress.blank` is the `static const` sentinel.

### `Clue` — `core/domain/models/clue.dart`

Answer-cell geometry (the one non-obvious rule):

- Across: `(startRow, startCol)` … `(startRow, startCol + length - 1)`
- Down:   `(startRow, startCol)` … `(startRow + length - 1, startCol)`

All clue-cell iteration goes through `ClueProgressCalculator`
([ADR-0002](docs/architecture/decisions/0002-clue-math-single-source.md)) —
never re-derive this geometry in widgets or notifiers.

### `FocusPosition` — `solve/domain/models/focus_position.dart`

Cursor `(row, col, direction)`. Direction toggles on repeated tap of the
same cell.

### `PuzzleMetadata` — `core/domain/models/puzzle_metadata.dart`

Identity semantics (the part that must not drift):

- `id` = `'local:' + sha256(canonicalJson).substring(0, 16)` — the stable FK
  used across the DB and in routing (encode/decode for routes, the id
  contains `:`).
- `checksum` = the **full** SHA-256 hex — used for duplicate detection in
  the DAO, not for identity.
- `(sourceId, sourcePuzzleId)` links an imported row back to its remote
  identifier (e.g. a Crosshare slug) so re-fetches match the existing row.
- `format` is `PuzzleFormat.puz | ipuz | jpz` — note local import currently
  accepts only `.puz`/`.ipuz`; `jpz` is a declared-but-unimplemented format.

### `Puzzle` — `core/domain/models/puzzle.dart`

Metadata + `Grid<SolutionCell>` + clues. The grid holds the full solution
and is never kept in memory after the session ends — the DB stores it as
`puzzles.canonicalJson`, reconstructed via `GridSerializer.fromJson` (keeps
puzzle reads to two queries: puzzle row + clue rows).

### `SolveState` — `solve/presentation/notifiers/solve_state.dart`

**Presentation layer only** — lives in `presentation/notifiers/`, not
`domain/`. Plain immutable class (contains `Grid<T>`, so not Freezed).
Semantics worth knowing:

- Owns the **live** solve; only `SolveNotifier` writes it
  ([ADR-0008](docs/architecture/decisions/0008-completion-data-authority.md)).
- `cleanSolveEligible` flips false once any reveal is used and disqualifies
  the personal best.
- `sortedClues` (across-then-down by number) is memoised — built once per
  state instance.
- Active/cross clue and word-highlight membership are **derived** getters,
  never stored.

---

## Enums — `core/domain/models/enums.dart`

| Enum | Values | Used by |
|------|--------|---------|
| `AppThemeMode` | `light`, `dark`, `system` | AppSettingsRepository (translated to Flutter `ThemeMode` in `app.dart`) |
| `Direction` | `across`, `down` | Clue, FocusPosition, SolveNotifier |
| `CellState` | `empty`, `filled`, `checkedCorrect`, `checkedIncorrect`, `revealed` | CellProgress, painter |
| `ColorblindMode` | `none`, `deuteranopia` | Settings, painter verification palette + `✓` / `✗` symbols |
| `PuzzleStatus` | `unsolved`, `inProgress`, `solved`, `solvedWithHelp`, `solvedWithReveal`, `revealed` | SolveState, SolveNotifier |
| `PuzzleFormat` | `puz`, `ipuz`, `jpz` | PuzzleMetadata; local import currently accepts `puz` and `ipuz` only |
| `EntryMode` | `normal`, `pencil`, `rebus` | `pencil` reserved for a future pencil-mode feature |
| `SourceType` | `free`, `subscription`, `local` | SourcesTable |
| `LicenseStatus` | `userImport`, `explicitPermission`, `openLicense`, `needsReview`, `prohibited` | SourcesTable |
| `CompletionType` | `clean`, `checked`, `hinted`, `revealed` | SolveSessionsTable, PuzzleCompletionsTable |

**The naming trap:** `usedReveal=true` on an otherwise-completed solve maps
to `CompletionType.hinted` (a reveal *action* was used), while
`CompletionType.revealed` means the whole puzzle was revealed.
`SolveRepositoryImpl._statusFromDb` and `SolveNotifier._deriveCompletionType`
must remain inverses — locked by a round-trip test; full mapping in
[`docs/architecture/completion-authority.md`](docs/architecture/completion-authority.md).

---

## DB ↔ Domain Mapping

| DB table | Domain type | Converted by |
|----------|-------------|-------------|
| `puzzles` row | `PuzzleMetadata` | `PuzzleDao._rowToMetadata()` |
| `puzzles.canonical_json` | `Grid<SolutionCell>` | `GridSerializer.fromJson()` |
| `clues` row | `Clue` | `PuzzleDao._clueRowToClue()` |
| `solve_sessions` row | `SolveState` fields | `SolveRepositoryImpl.createOrResumeSession()` |
| `cell_progress` row | `CellProgress` | `SolveSessionDao` (save/load per cell) |
| join `solve_sessions` + `puzzles` | `CompletedSessionStat` record (typedef in `stats_dao.dart`) | `StatsDao.getCompletedSessionsWithPuzzle()` |

---

## Import models

- **`ParseError`** (`import/domain/models/parse_error.dart`) — enum of typed
  parse failures (invalid/unsupported format, missing data, encoding,
  the 5 MB `fileTooLarge` guard, checksum mismatch, unknown).
- **`ImportJobResult`** (`import_repository_impl.dart`) — sealed
  `JobSuccess | JobDuplicate | JobFailure`. The `Job` prefix exists to avoid
  a name collision with the UI's `ImportState` variants (see CONVENTIONS.md
  → Naming).
- **`ImportState`** (`import_notifier.dart`) — Freezed **union**
  (multi-factory → plain `class`, not `abstract`):
  `idle | loading | success | duplicate | failure`. On success the notifier
  calls `ref.invalidate(puzzleListProvider)` so the home list refreshes.

## `Result<T, E>` — `core/utils/result.dart`

Sealed `Ok<T, E> | Err<T, E>`; parsers and repository methods return it
instead of throwing across layer boundaries (CONVENTIONS.md → `Result`
usage). Consumption pattern:

```dart
final result = await parser.parse(bytes);   // Result<Puzzle, ParseError>
switch (result) {
  case Ok(:final value):  // use value
  case Err(:final error): // handle typed error
}
```

## Archive & stats models

- **`ArchiveEntry`** — `PuzzleMetadata` + nullable latest `solve_sessions`
  row (null → never started), with status helpers and a `sizeLabel`
  (`Mini` / `15×15` / `21×21` / `N×M`).
- **`StatsData`** — plain immutable aggregate with an `empty` sentinel.
  Semantic details that matter: `currentStreak` counts through today *or*
  yesterday-if-today-unsolved; personal bests are **clean solves only**,
  bucketed by size (mini ≤ 7×7, 15×15, 21×21); `completionRate` =
  completed ÷ started. Streak attribution uses `solvedDateLocal` — the date
  the user solved, not the puzzle's publish date (no back-fill inflation;
  see ARCHITECTURE.md → Feature: home).

## Puzzle sources

- **`PuzzleSource`** (`import/domain/repositories/puzzle_source.dart`) — the
  interface every source implements; `licenseStatus` drives enforcement,
  `rawPayloadRetention: false` means only canonical JSON is retained.
- **`SourceRegistry`** — `prohibited` sources **cannot be registered**
  (`SourceRegistrationException`); `needsReview` sources register but are
  excluded from `enabledSources`. This is the code half of the legal
  guardrail in CONVENTIONS.md;
  [ADR-0006](docs/architecture/decisions/0006-crosshare-source-approval.md)
  records the one approved online source.

---

## Sync models — `core/sync/models/`

Design: [`docs/architecture/sync-design.md`](docs/architecture/sync-design.md);
versioning rules: [`docs/architecture/compatibility.md`](docs/architecture/compatibility.md).
Semantics that callers must respect:

- **`SyncState`** — hand-written sealed class (not Freezed):
  `SyncDisabled | SyncSignedOut | SyncIdle | SyncRunning | SyncError`.
  Switch exhaustively. `SyncError.transient: true` → orchestrator retries on
  the next trigger; `false` → the user must act (re-sign-in, free quota).
- **`SyncResult`** — `{pushed, pulled, conflicts, duration}` per pass;
  `conflicts` counts merges the strategy *resolved* (informational, not
  errors). `SyncResult.zero` + `operator +` fold per-namespace results.
- **`SyncBlob`** — the envelope around every namespace payload:
  `{schemaVersion, deviceId, syncVersion, updatedAt, payload}`.
  `decode()` returns **null** for malformed bytes *or* a schema newer than
  `currentSchemaVersion` (currently **1**) — callers treat that as "skip".
  The mixed-version write policy is
  [ADR-0016](docs/architecture/decisions/0016-mixed-version-sync-policy.md).
- **`SyncNamespace`** — `puzzles/ | sessions/ | completions/ | settings/`
  blob-key prefixes; each namespace owns its merge rule (ADR-0009).
- **`SyncTransport`** (`core/sync/transport/`) — the only platform-aware
  piece: CRUD on named blobs + `account()` (silent) / `signIn()`
  (interactive only where `supportsInteractiveSignIn`). Implementations:
  iCloud (iOS), Google Drive (Android), `NoOp` (other platforms), `Fake`
  (tests). `SyncOrchestrator` is the presentation-facing facade; the
  `SyncController` provider bridges it to Settings/onboarding UI.

---

## Challenge Boards models — `challenge_boards/domain/models/challenge_models.dart`

Pure data classes (`package:meta`, no Flutter) for the online feature. They
map to the **server's** D1 schema, not the local Drift database — the source
of truth is the numbered SQL in
[`crosscue/backend/challenge_boards/migrations/`](crosscue/backend/challenge_boards/migrations/),
and the wire shapes are documented in
[`crosscue/backend/challenge_boards/API.md`](crosscue/backend/challenge_boards/API.md).
Client-side persistence is limited to the identity (auth token in secure
storage, recovery bundle in `app_settings`) and the offline result outbox —
the sync exclusions for these are deliberate (see threat model → assets).
