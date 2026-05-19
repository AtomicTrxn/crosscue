# Architecture — Crosscue

## Overview

Clean Architecture with three layers per feature: **Data → Domain → Presentation**.
Features live under `lib/features/<name>/`. Shared infrastructure lives under `lib/core/`.

```
lib/
├── main.dart                        # Entry point, ProviderScope
├── app.dart                         # MaterialApp + router wiring
├── core/
│   ├── audio/                       # SoundPlayer (in-app feedback beep)
│   ├── constants/                   # AppLinks (privacy/repo URLs), CrosscueRetention
│   ├── database/                    # Drift DB definition + all tables
│   ├── domain/models/               # ALL shared domain models: Puzzle, Clue, Grid, SolutionCell,
│   │                                #   enums, PuzzleMetadata (solve-only models stay in features/solve)
│   ├── entitlement/                 # License / paywall stubs (all features free)
│   ├── providers/                   # App-wide Riverpod providers
│   ├── routing/                     # go_router config + route constants
│   ├── sync/                        # SyncOrchestrator + per-namespace adapters + transports
│   │                                #   (see docs/architecture/sync-design.md)
│   ├── telemetry/                   # CrashReporter (local-only log)
│   ├── theme/                       # Material 3 theme + CrosswordTheme extension
│   └── utils/                       # Result<T,E>, shared formatting helpers
└── features/
    ├── home/                        # Puzzle list screen
    ├── import/                      # File pick → parse → persist pipeline
    ├── solve/                       # Interactive solve screen (grid + clues + timer)
    ├── archive/                     # Solved puzzles history with sort/filter/delete
    ├── stats/                       # Solve statistics (streaks, times, personal bests)
    ├── settings/                    # App settings screen (theme, haptics, clear data)
    └── onboarding/                  # 3-step interactive first-launch onboarding
```

---

## Layer Rules

| Layer | Owns | May import |
|-------|------|-----------|
| **Domain** | Models, enums, abstract interfaces | Nothing outside `core/utils` |
| **Data** | DAOs, parsers, repository impls | Domain models + `core/database` |
| **Presentation** | Notifiers, screens, widgets | Domain models + data repositories (via providers) |

> Domain models **never** import Flutter. Presentation **never** directly touches Drift tables.

---

## Feature: `home`

Lists imported puzzles and launches the import flow. Below that, a
"Past puzzles" section lets the user browse and download missed daily
minis from the Crosshare archive — visible on both empty and populated
states so new users see depth immediately.

```
home/
├── domain/models/
│   └── past_puzzle_item.dart            # CrosshareEntry + localPuzzleId
└── presentation/
    ├── notifiers/
    │   ├── past_puzzles_notifier.dart    # AsyncNotifier<PastPuzzlesState>
    │   └── past_puzzles_state.dart       # items, cursor, hasMore, per-row download flags
    ├── providers/
    │   └── home_providers.dart           # puzzleListProvider
    ├── screens/
    │   └── home_screen.dart              # featured card, recent list, _EmptyState
    └── widgets/
        └── past_puzzles_section.dart     # PastPuzzlesSection + rows + footer
```

**Data flow:**
```
HomeScreen (ref.watch puzzleListProvider)
  → ImportRepository.getAllMetadata()   # sorted by createdAt DESC
  → _PuzzleTile.onTap
      → context.push('/solve/${Uri.encodeComponent(puzzle.id)}')

PastPuzzlesSection (ref.watch pastPuzzlesProvider)
  → PastPuzzlesNotifier.build()
      → CrosshareDownloader.fetchMonth(year, month)   # walks backward, monthly
      → join with ImportRepository.getAllMetadata()    # sourcePuzzleId lookup
  → row tap
      → if imported: context.push('/solve/...')
      → else: PastPuzzlesNotifier.download(entry)
          → CrosshareDownloader.downloadById(id)
          → ImportRepository.importBytes(..., sourcePuzzleId: entry.id)
          → context.push('/solve/...')
```

**Streak interaction:** Back-filled solves use `solvedDateLocal` (the date
the user solves) for streak attribution, not the puzzle's publish date.
Solving seven missed days all on Saturday counts as one day of streak,
not seven — no artificial streak inflation from back-filling.

---

## Feature: `import`

Handles the full pipeline from raw bytes → parsed puzzle → persisted in DB.

```
import/
├── domain/
│   ├── models/parse_error.dart          # ParseError enum (invalidFormat, fileTooLarge, etc.)
│   └── repositories/
│       ├── puzzle_parser.dart           # PuzzleParser abstract interface
│       └── puzzle_source.dart          # PuzzleSource abstract interface (id, licenseStatus, etc.)
├── data/
│   ├── parsers/puz_parser.dart          # .puz binary parser (rebus, circles, 5 MB guard)
│   ├── parsers/ipuz_parser.dart         # .ipuz JSON parser (5 MB guard)
│   ├── daos/puzzle_dao.dart             # Drift DAO: insert/get/delete puzzles + clues
│   ├── daos/grid_serializer.dart        # Grid<SolutionCell> ↔ JSON string (for DB storage)
│   ├── downloaders/crosshare_downloader.dart  # HTTP + HTML scraper for Crosshare Daily Mini
│   ├── repositories/import_repository_impl.dart  # Orchestrates parse + duplicate check + persist
│   ├── services/crosshare_auto_download_service.dart  # Foreground-trigger auto-downloader
│   └── sources/
│       ├── source_registry.dart         # SourceRegistry + SourceRegistrationException
│       └── local_import_source.dart     # LocalImportSource (id='local_import', userImport)
└── presentation/
    ├── providers/import_providers.dart  # importRepositoryProvider (keepAlive)
    ├── notifiers/
    │   ├── import_notifier.dart         # ImportNotifier + @freezed ImportState (idle/picking/parsing/success/duplicate/failure)
    │   └── crosshare_notifier.dart      # CrosshareNotifier + @freezed CrosshareState
    └── screens/import_screen.dart       # File picker UI
```

**Data flow:**
```
ImportScreen
  → ImportNotifier.pickAndImport()
    → FilePicker (FileType.any — see CONVENTIONS.md)
    → PuzParser / IpuzParser (canParse → parse → Result<Puzzle, ParseError>)
      → ImportRepository.importBytes()
      → PuzzleDao.existsByChecksum()   # duplicate guard
      → PuzzleDao.insertPuzzle()       # transaction: puzzles + clues rows
    → state = ImportSuccess / ImportDuplicate / ImportFailure
  → ref.invalidate(puzzleListProvider) → navigate home
```

---

## Feature: `solve`

Owns solve-specific models and the interactive grid. Shared puzzle models and enums
live in `core/domain/models/` (see Core: Domain Models below).

```
solve/
├── domain/
│   ├── models/
│   │   ├── cell_progress.dart    # @freezed abstract class — one cell of user progress (solve-only)
│   │   ├── focus_position.dart   # @freezed abstract class — cursor row/col/direction (solve-only)
│   │   └── solve_errors.dart     # sealed SolveLoadError, PuzzleNotFoundError, SolveSessionLoadError
│   ├── repositories/solve_repository.dart # Abstract solve contract
│   └── services/
│       └── clue_progress_calculator.dart  # cellsFor(Clue) + isWordComplete — single source of truth
├── data/
│   ├── daos/solve_session_dao.dart          # Autosave, resume, getLatestSession()
│   └── repositories/solve_repository_impl.dart  # createOrResumeSession + save
└── presentation/
    ├── providers/solve_providers.dart  # solveRepositoryProvider (keepAlive)
    ├── notifiers/
    │   ├── solve_state.dart      # Plain immutable class (not Freezed — contains Grid<T>); memoizes sortedClues
    │   └── solve_notifier.dart   # @riverpod AsyncNotifier family (puzzleId: String)
    ├── screens/
    │   └── solve_screen.dart     # Scaffold: AppBar + CrosswordGrid + CluePanel + completion sheet
    └── widgets/
        ├── crossword_grid.dart         # ConsumerStatefulWidget — tap + long-press + keyboard input
        ├── crossword_grid_painter.dart # CustomPainter — cell rendering
        └── clue_panel.dart             # Active clue + cross clue display
```

**Data flow:**
```
SolveScreen (ref.watch solveProvider(puzzleId))
  → SolveNotifier.build(puzzleId)
      → ImportRepository.getPuzzle(id)   # loads from DB
      → Grid<CellProgress>.generate(...)     # blank progress
      → _startTimer()                        # Stream<int>.periodic tick
      → return SolveState(puzzle, progress, focus, ...)
  → CrosswordGrid
      → onTapDown → SolveNotifier.tapCell(row, col)
      → FocusNode.onKeyEvent → SolveNotifier.inputLetter / backspace
      → TextField.onChanged  → SolveNotifier.inputLetter / backspace (soft kbd)
  → CluePanel (reads solveState.activeClue + crossClue)
```

**Rebus entry** (G6 — see `docs/architecture/rebus-entry.md`):
Solvers reach the rebus dialog through three surfaces, all routed
through one helper, `showRebusDialogForFocus`:

  1. The always-visible **"Rebus"** key on the bottom-right of
     `CrosswordKeyboard` (NYT-aligned position and label).
  2. The **"Enter rebus"** item in the cell long-press menu inside
     `CrosswordGrid`.
  3. The **`Esc`** physical-keyboard shortcut.

Acceptance is centralized on `SolutionCell.accepts(entered)` and used
by `_checkCompletion` (in `SolveNotifier`), `GridProgressMutator.checkCells`,
and `ClueProgressCalculator.isClueCorrect`. The rule accepts exact
matches, the first letter of a rebus answer (so solvers who never
discover rebus mode can still complete), and bidirectional rebuses
delimited with "/" (e.g. `"PB/AU"`).

---

## Feature: `archive`

Lists all imported puzzles with their latest solve session status.

```
archive/
├── domain/models/archive_entry.dart            # ArchiveEntry (metadata + latest session status)
├── data/repositories/archive_repository_impl.dart  # getArchiveEntries(), deletePuzzle()
└── presentation/
    ├── providers/archive_providers.dart         # archiveRepositoryProvider (keepAlive), archiveEntriesProvider
    └── screens/archive_screen.dart              # Sort (import/puzzle date/title) + filter chips + long-press delete
```

---

## Feature: `stats`

Aggregated solve statistics for the current user.

```
stats/
├── domain/models/stats_data.dart               # StatsData plain immutable class
├── data/
│   ├── daos/stats_dao.dart                     # @DriftAccessor join — returns CompletedSessionStat records
│   └── repositories/stats_repository_impl.dart # Pure Dart computation (no Drift dependency)
└── presentation/
    ├── providers/stats_providers.dart           # statsRepositoryProvider (keepAlive), statsDataProvider
    └── screens/stats_screen.dart               # Streak, totals, times, personal bests, completion rate cards
```

**`CompletedSessionStat` typedef** (Dart 3 record, defined in `stats_dao.dart`):
```dart
typedef CompletedSessionStat = ({
  String? completionType,
  int elapsedMs,
  String? solvedDateLocal,
  int width,
  int height,
});
```

---

## Feature: `settings`

App configuration: theme, haptics, sounds, puzzle sources, privacy, and about.

```
settings/
├── data/daos/app_settings_dao.dart               # Key/value settings store (Drift)
└── presentation/
    ├── providers/settings_providers.dart          # appSettingsProvider + per-setting notifiers
    ├── widgets/settings_rows.dart                 # Shared: SettingsSwitchRow, SettingsNavRow,
    │                                              #   SettingsSectionHeader, SettingsRowDivider
    └── screens/
        ├── settings_screen.dart                   # Root settings (theme, haptics, sounds, skip cells)
        ├── source_management_screen.dart          # Puzzle source list (local + Crosshare)
        ├── crosshare_settings_screen.dart         # Crosshare Daily Mini on/off + schedule config
        └── privacy_screen.dart                    # Crash reporting, data export/import, clear all data
```

---

## Core: Theme System

`lib/core/theme/` owns the app palette and exposes crossword-specific colors
through `CrosswordTheme`. The current palette reference lives in
[`design/Crosscue Color Guide.html`](design/Crosscue%20Color%20Guide.html).

The solve grid uses a semantic visual model rather than letting every state
change every token:

- **position** uses background fills (focused cell, active word)
- **verification** uses letter color (`checkedCorrect`, `checkedIncorrect`)
- **reveal** uses a fixed reveal background
- **completion** uses the fixed green celebration pair
- **colorblind mode** remaps verification to blue/orange and adds `✓` / `✗`
  symbols so correctness is never conveyed by color alone

Grid semantics are intentionally kept outside Android dynamic-color overrides;
they carry puzzle meaning, not just decoration.

---

## Core: Domain Models

Shared models consumed by more than one feature. Solve-only models (`CellProgress`,
`FocusPosition`) remain in `features/solve/domain/models/`.

```
core/domain/models/
├── enums.dart             # Direction, CellState, PuzzleStatus, EntryMode,
│                          #   PuzzleFormat, SourceType, LicenseStatus, CompletionType
├── grid.dart              # Grid<T> — plain Dart class (NOT Freezed — generics)
├── solution_cell.dart     # @freezed abstract class — one cell in the solution grid
├── clue.dart              # @freezed abstract class — number, direction, text, position
├── puzzle.dart            # @freezed abstract class — metadata + Grid<SolutionCell> + clues
└── puzzle_metadata.dart   # @freezed abstract class — id, title, author, format, size, difficulty
```

Consumers outside `solve/`: import parsers, archive, stats, core database, settings.

---

## Core: Database

```
core/database/
├── app_database.dart           # @DriftDatabase declaration; PuzzleDao, SolveSessionDao,
│                               #   AppSettingsDao, StatsDao, PuzzleCompletionDao accessors
└── tables/
    ├── sources_table.dart            # Puzzle sources (e.g. 'local_import')
    ├── puzzles_table.dart            # One row per imported puzzle
    ├── clues_table.dart              # One row per clue (FK → puzzles)
    ├── solve_sessions_table.dart     # One session per puzzle attempt
    ├── cell_progress_table.dart      # Per-cell user progress (FK → solve_sessions)
    ├── puzzle_completions_table.dart # Immutable per-completion history (streaks/PBs)
    ├── imported_solve_stats_table.dart # Pre-imported solve stats from external sources
    └── app_settings_table.dart       # Key/value app settings
```

**Relationship diagram:**
```
sources (id PK)
  └─< puzzles (sourceId FK)
        └─< clues (puzzleId FK, cascade delete)
        └─< solve_sessions (puzzleId FK, cascade delete)
        │     └─< cell_progress (sessionId FK, cascade delete)
        └─< puzzle_completions (puzzleId FK, cascade delete)
```

The `puzzles.canonicalJson` column stores the full `Grid<SolutionCell>` as JSON
(via `GridSerializer`). This avoids a separate cells table and keeps puzzle reads
to two queries (puzzle row + clues rows).

---

## Core: Routing

```
core/routing/
├── routes.dart      # Route path constants (always use these, never raw strings)
├── app_router.dart  # GoRouter config — redirect logic, route tree
└── app_shell.dart   # StatefulShellRoute (4-tab bottom nav)
```

**Route hierarchy:**

| Route | Type | Screen |
|-------|------|--------|
| `/` | Shell tab (Home) | `HomeScreen` |
| `/archive` | Shell tab | `ArchiveScreen` |
| `/stats` | Shell tab | `StatsScreen` |
| `/settings` | Shell tab | `SettingsScreen` |
| `/settings/sources` | Nested under `/settings` | `SourceManagementScreen` |
| `/settings/sources/crosshare` | Nested under `/settings/sources` | `CrosshareSettingsScreen` |
| `/settings/privacy` | Nested under `/settings` | `PrivacyScreen` |
| `/onboarding` | Full-page (no shell) | `OnboardingScreen` |
| `/import` | Full-page (no shell) | `ImportScreen` |
| `/solve/:puzzleId` | Full-page (no shell) | `SolveScreen` |

Navigate to solve: `context.push(Routes.solveFor(Uri.encodeComponent(puzzle.id)))`
`SolveNotifier` receives: `Uri.decodeComponent(puzzleId)` before DB lookup.

Always use `Routes` constants — never raw strings.

---

## Core: Providers

All shared infrastructure is exposed via Riverpod providers in `lib/core/providers/`.
Use `ref.watch(providerNameProvider)` from any feature presentation layer.

Provider categories:
- **Database & repositories** — exposed as their interface type; all `@Riverpod(keepAlive: true)`.  
  `appDatabaseProvider`, `importRepositoryProvider`, `solveRepositoryProvider`,  
  `archiveRepositoryProvider`, `statsRepositoryProvider`, `appSettingsProvider`
- **HTTP / network** — `dioProvider`, `crosshareDownloaderProvider`
- **Platform services** — `crashReporterProvider`, `soundPlayerProvider`, `appVersionProvider`
- **Lifecycle** — `CrosscueApp` itself registers a `WidgetsBindingObserver` that calls
  `crosshareAutoDownloadServiceProvider` on `resumed`. See `app.dart`.
- **Settings & user preferences** — `settings_providers.dart`: `hasSeenOnboardingProvider`,  
  `themeModeProvider`, `hapticsEnabledProvider`, `soundsEnabledProvider`, `skipFilledCellsProvider`,  
  `colorblindModeProvider`, `crashReportingProvider`
- **Source registry** — `sourceRegistryProvider` exposes all registered `PuzzleSource` definitions

`keepAlive: true` on all repository and infrastructure providers — these must survive navigation.

Use IDE autocomplete (`*Provider`) to discover the full list — this section is categorical,
not exhaustive, to avoid going stale.

---

## Adding a New Feature — Checklist

1. **Domain model**
   - If the model will be consumed by more than one feature → `core/domain/models/<model>.dart`
   - If solve-only → `features/solve/domain/models/<model>.dart`
   - If feature-specific → `features/<name>/domain/models/<model>.dart`
   - Use `@freezed abstract class` for single-factory value objects
   - Use plain `class` for anything containing `Grid<T>` generics
   - Run `build_runner` after

2. **DB table** (if persisted) (`core/database/tables/<name>_table.dart`)
   - Register in `app_database.dart` `@DriftDatabase(tables: [...])`
   - Add DAO method in the relevant DAO
   - Run `build_runner` after

3. **Repository**
   - Abstract interface → `features/<name>/domain/repositories/<name>_repository.dart`
   - Concrete impl → `features/<name>/data/repositories/<name>_repository_impl.dart`
   - Expose the **interface type** via a `@Riverpod(keepAlive: true)` provider; inject the impl

4. **Notifier** (`features/<name>/presentation/notifiers/<name>_notifier.dart`)
   - `@riverpod class XyzNotifier extends _$XyzNotifier`
   - Run `build_runner` after

5. **Screen + widgets** (`features/<name>/presentation/screens/` and `widgets/`)

6. **Route** — add path constant to `routes.dart`, add `GoRoute` to `app_router.dart`

7. **`flutter analyze`** — must be clean before committing

---

## Recent Architectural Decisions

- **Crosshare source approval (v1.1, May 2026)**: Crosshare Daily Mini approved
  as `openLicense`. The source is gated behind the `SourceRegistry` legal guardrail;
  see `source_registry.dart` and `CONVENTIONS.md` "Source approval documentation".

- **Settings nested routes (v1.1, May 2026)**: Sub-pages under `/settings/sources`,
  `/settings/sources/crosshare`, and `/settings/privacy` are nested `GoRoute` entries
  inside the Settings shell branch. Always use absolute `Routes` constants when navigating.

- **Cell-progress orphan fix (Sprint 1)**: `saveCellProgress` deletes-then-inserts
  to avoid stale rows when a user backtracks or resets a cell.

- **Clue math consolidation (Sprint 4)**: All clue-cell iteration and word-completion
  logic lives in `features/solve/domain/services/clue_progress_calculator.dart`.
  Do not duplicate `_clueCells` / `_isWordComplete` helpers in widgets or notifiers.

- **Settings widget library (Sprint 4)**: Shared row widgets (`SettingsSwitchRow`,
  `SettingsNavRow`, `SettingsSectionHeader`, `SettingsRowDivider`) live in
  `features/settings/presentation/widgets/settings_rows.dart`. Use them in all
  settings-adjacent screens to keep visual consistency.

- **Freeze-sealed error types (Sprint 4)**: `SolveLoadError` and its subtypes are
  plain sealed classes in `solve/domain/models/solve_errors.dart`. Presentation
  switches on error type via `switch (e) { PuzzleNotFoundError() => ..., ... }`.

- **Runtime app version (Sprint 5)**: `appVersionProvider` in `core_providers.dart`
  reads the version from `PackageInfo.fromPlatform()`. Never hardcode a version string.

- **Completion data authority (Sprint E, May 2026)**: Hybrid model with named
  authorities — `SolveState` owns the live solve, `puzzle_completions` owns
  completion history (stats, streaks, PBs), `solve_sessions` is the resumable
  session cache for Archive and resume. See
  [`docs/architecture/completion-authority.md`](docs/architecture/completion-authority.md)
  for the rules, the round-trip mapping between `PuzzleStatus` and
  `CompletionType`, the five named divergence windows, and the planned
  code tightenings.

- **Sync foundation (G5, May 2026)**: Cross-device sync of puzzles,
  solve sessions, completion history, and a settings allowlist. Local-only
  build still default; schema v5 adds sync-readiness columns. Per-namespace
  adapters own merge rules (content-addressable union for puzzles,
  client-uuid union for completions, LWW + best-progress for sessions, LWW
  for settings) behind a platform-pluggable `SyncTransport`. iCloud / Drive
  transports and the settings UI are deferred — see
  [`docs/architecture/sync-design.md`](docs/architecture/sync-design.md)
  and [`docs/architecture/sync-progress.md`](docs/architecture/sync-progress.md).
