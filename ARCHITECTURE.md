# Architecture — Crosscue

## Overview

Clean Architecture with three layers per feature: **Data → Domain → Presentation**.
Features live under `lib/features/<name>/`. Shared infrastructure lives under `lib/core/`.

```
lib/
├── main.dart                        # Entry point, ProviderScope
├── app.dart                         # MaterialApp + router wiring
├── core/
│   ├── database/                    # Drift DB definition + all tables
│   ├── providers/                   # App-wide Riverpod providers
│   ├── routing/                     # go_router config + route constants
│   ├── theme/                       # Material 3 theme + CrosswordTheme extension
│   ├── utils/                       # Result<T,E> type
│   ├── entitlement/                 # License / paywall stubs (Phase 1: free only)
│   ├── sync/                        # Sync adapter interface + NoOp impl
│   └── telemetry/                   # Crash reporter stub
└── features/
    ├── home/                        # Puzzle list screen
    ├── import/                      # File pick → parse → persist pipeline
    ├── solve/                       # Interactive solve screen (grid + clues + timer)
    ├── archive/                     # Solved puzzles history (stub)
    ├── stats/                       # Solve statistics (stub)
    ├── settings/                    # App settings (stub)
    └── onboarding/                  # First-launch onboarding (in-memory flag; Phase 5)
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

Lists imported puzzles and launches the import flow.

```
home/
└── presentation/
    └── screens/
        └── home_screen.dart   # HomeScreen + _PuzzleList + _PuzzleTile + _EmptyState
                               # puzzleListProvider (@riverpod Future<List<PuzzleMetadata>>)
                               # Invalidated by ImportNotifier after successful import
```

**Data flow:**
```
HomeScreen (ref.watch puzzleListProvider)
  → ImportRepositoryImpl.getAllMetadata()   # sorted by createdAt DESC
  → _PuzzleTile.onTap
      → context.push('/solve/${Uri.encodeComponent(puzzle.id)}')
```

---

## Feature: `import`

Handles the full pipeline from raw bytes → parsed puzzle → persisted in DB.

```
import/
├── domain/
│   ├── models/parse_error.dart          # ParseError enum
│   └── repositories/puzzle_parser.dart  # PuzzleParser abstract interface
├── data/
│   ├── parsers/puz_parser.dart          # .puz binary parser (rebus, circles)
│   ├── parsers/ipuz_parser.dart         # .ipuz JSON parser
│   ├── daos/puzzle_dao.dart             # Drift DAO: insert/get/delete puzzles + clues
│   ├── daos/grid_serializer.dart        # Grid<SolutionCell> ↔ JSON string (for DB storage)
│   └── repositories/import_repository_impl.dart  # Orchestrates parse + duplicate check + persist
└── presentation/
    ├── providers/import_providers.dart  # importRepositoryProvider (keepAlive)
    ├── notifiers/import_notifier.dart   # ImportNotifier + ImportState sealed class
    └── screens/import_screen.dart       # File picker UI
```

**Data flow:**
```
ImportScreen
  → ImportNotifier.pickAndImport()
    → FilePicker (FileType.any — see CONVENTIONS.md)
    → PuzParser / IpuzParser (canParse → parse → Result<Puzzle, ParseError>)
    → ImportRepositoryImpl.importBytes()
      → PuzzleDao.existsByChecksum()   # duplicate guard
      → PuzzleDao.insertPuzzle()       # transaction: puzzles + clues rows
    → state = ImportSuccess / ImportDuplicate / ImportFailure
  → ref.invalidate(puzzleListProvider) → navigate home
```

---

## Feature: `solve`

Owns all domain models (other features import from here). Handles the interactive grid.

```
solve/
├── domain/
│   └── models/
│       ├── enums.dart            # Direction, CellState, PuzzleStatus, PuzzleFormat, etc.
│       ├── grid.dart             # Grid<T> — plain Dart class (NOT Freezed — generics)
│       ├── solution_cell.dart    # @freezed abstract class — one cell in the solution
│       ├── cell_progress.dart    # @freezed abstract class — one cell of user progress
│       ├── clue.dart             # @freezed abstract class
│       ├── focus_position.dart   # @freezed abstract class
│       ├── puzzle_metadata.dart  # @freezed abstract class
│       └── puzzle.dart           # @freezed abstract class — full puzzle (metadata + grid + clues)
│   # NOTE: solve has no data/ layer yet. Sprint 4 adds:
│   #   data/daos/solve_session_dao.dart   — autosave + resume
│   #   data/repositories/solve_repository_impl.dart
└── presentation/
    ├── notifiers/
    │   ├── solve_state.dart      # Plain immutable class (not Freezed — contains Grid<T>)
    │   └── solve_notifier.dart   # @riverpod AsyncNotifier family (puzzleId: String)
    ├── screens/
    │   └── solve_screen.dart     # Scaffold: AppBar + CrosswordGrid + CluePanel
    └── widgets/
        ├── crossword_grid.dart         # ConsumerStatefulWidget — tap + keyboard input
        ├── crossword_grid_painter.dart # CustomPainter — cell rendering
        └── clue_panel.dart             # Active clue + cross clue display
```

**Data flow:**
```
SolveScreen (ref.watch solveProvider(puzzleId))
  → SolveNotifier.build(puzzleId)
      → ImportRepositoryImpl.getPuzzle(id)   # loads from DB
      → Grid<CellProgress>.generate(...)     # blank progress
      → _startTimer()                        # Stream<int>.periodic tick
      → return SolveState(puzzle, progress, focus, ...)
  → CrosswordGrid
      → onTapDown → SolveNotifier.tapCell(row, col)
      → FocusNode.onKeyEvent → SolveNotifier.inputLetter / backspace
      → TextField.onChanged  → SolveNotifier.inputLetter / backspace (soft kbd)
  → CluePanel (reads solveState.activeClue + crossClue)
```

---

## Core: Database

```
core/database/
├── app_database.dart           # @DriftDatabase declaration + PuzzleDao accessor
└── tables/
    ├── sources_table.dart      # Puzzle sources (e.g. 'local_import')
    ├── puzzles_table.dart      # One row per imported puzzle
    ├── clues_table.dart        # One row per clue (FK → puzzles)
    ├── cell_progress_table.dart  # Per-cell user progress (FK → solve_sessions)
    ├── solve_sessions_table.dart # One session per puzzle attempt
    └── app_settings_table.dart   # Key/value app settings
```

**Relationship diagram:**
```
sources (id PK)
  └─< puzzles (sourceId FK)
        └─< clues (puzzleId FK, cascade delete)
        └─< solve_sessions (puzzleId FK, cascade delete)
              └─< cell_progress (sessionId FK, cascade delete)
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

**Route tree:**
```
/onboarding          → OnboardingScreen   (full page, no shell)
/import              → ImportScreen        (full page, no shell)
/solve/:puzzleId     → SolveScreen         (full page, no shell)
/                    → HomeScreen          (tab 0)
/archive             → ArchiveScreen       (tab 1)
/stats               → StatsScreen         (tab 2)
/settings            → SettingsScreen      (tab 3)
```

Navigate to solve: `context.push('/solve/${Uri.encodeComponent(puzzle.id)}')`
SolveNotifier receives: `Uri.decodeComponent(puzzleId)` before DB lookup.

---

## Core: Providers

```
core/providers/core_providers.dart
  appDatabaseProvider  — @Riverpod(keepAlive: true) AppDatabase
                         opens the Drift DB at app start

import/.../import_providers.dart
  importRepositoryProvider — @Riverpod(keepAlive: true) ImportRepositoryImpl
                              depends on appDatabaseProvider
```

`keepAlive: true` on both — these must survive navigation and never be disposed.

---

## Adding a New Feature — Checklist

1. **Domain model** (`features/<name>/domain/models/<model>.dart`)
   - Use `@freezed abstract class` for single-factory value objects
   - Use plain `class` for anything containing `Grid<T>` generics
   - Run `build_runner` after

2. **DB table** (if persisted) (`core/database/tables/<name>_table.dart`)
   - Register in `app_database.dart` `@DriftDatabase(tables: [...])`
   - Add DAO method in the relevant DAO
   - Run `build_runner` after

3. **Repository** (`features/<name>/data/repositories/<name>_repository_impl.dart`)
   - Expose via a `@Riverpod(keepAlive: true)` provider in a `providers/` file

4. **Notifier** (`features/<name>/presentation/notifiers/<name>_notifier.dart`)
   - `@riverpod class XyzNotifier extends _$XyzNotifier`
   - Run `build_runner` after

5. **Screen + widgets** (`features/<name>/presentation/screens/` and `widgets/`)

6. **Route** — add path constant to `routes.dart`, add `GoRoute` to `app_router.dart`

7. **`flutter analyze`** — must be clean before committing

8. **Update `SPRINTS.md`** — mark tasks ✅ as they land; update the sprint goal if scope changed

9. **Update `research/INDEX.md`** — mark topics ✅ / 🔄 as their conclusions are implemented
