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
│   ├── background/                   # WidgetRefreshScheduler + headless callback
│   │                                #   (BGAppRefreshTask / WorkManager, #175)
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
    └── onboarding/                  # 4-step first-launch flow (welcome, source, sync, fetch)
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
│   │   ├── check_result.dart     # Outcome of a check action (correct/incorrect counts)
│   │   ├── focus_position.dart   # @freezed abstract class — cursor row/col/direction (solve-only)
│   │   └── solve_errors.dart     # sealed SolveLoadError, PuzzleNotFoundError, SolveSessionLoadError
│   ├── repositories/solve_repository.dart # Abstract solve contract
│   └── services/
│       ├── clue_progress_calculator.dart  # cellsFor(Clue) + isWordComplete — single source of truth
│       ├── grid_progress_mutator.dart     # Pure cell mutations + checkCells (no notifier/Flutter deps)
│       └── solve_focus_navigator.dart     # Focus movement / direction-toggle / clue traversal logic
├── data/
│   ├── daos/
│   │   ├── solve_session_dao.dart          # Autosave, resume, getLatestSession()
│   │   └── puzzle_completion_dao.dart       # Immutable per-completion history (streaks/PBs)
│   └── repositories/solve_repository_impl.dart  # createOrResumeSession + save
└── presentation/
    ├── providers/solve_providers.dart  # solveRepositoryProvider (keepAlive)
    ├── notifiers/
    │   ├── solve_state.dart           # Plain immutable class (not Freezed — contains Grid<T>); memoizes sortedClues
    │   ├── solve_notifier.dart        # @riverpod AsyncNotifier family (puzzleId: String) — orchestrator
    │   └── solve_elapsed_notifier.dart # SolveElapsedSeconds — per-second tick isolated off the rebuild path (#130)
    ├── screens/
    │   └── solve_screen.dart     # Scaffold: AppBar + CrosswordGrid + CluePanel + completion sheet
    └── widgets/
        ├── crossword_grid.dart         # ConsumerStatefulWidget — tap + long-press
        ├── crossword_grid_input.dart   # Physical + soft-keyboard input plumbing
        ├── crossword_grid_painter.dart # CustomPainter — cell rendering
        ├── crossword_grid_effects.dart # Completion / verification visual effects
        ├── crossword_keyboard.dart     # On-screen keyboard (incl. Rebus key)
        ├── clue_panel.dart             # Active clue + cross clue display
        ├── solve_app_bar.dart          # AppBar: title, timer, pause, check/reveal menu
        ├── pause_overlay.dart          # Pause scrim over the grid
        └── completion_sheet.dart       # Post-solve summary (time, method, PB, confetti)
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
        ├── sync_settings_screen.dart              # Sync opt-in + status (SyncController; iCloud/Drive)
        └── privacy_screen.dart                    # Crash reporting, data export/import, clear all data
```

The `providers/` folder also holds `sync_providers.dart` (`SyncController`),
which bridges the `core/sync` orchestrator to the settings + onboarding UI.

---

## Feature: `challenge_boards`

Private friend leaderboards for daily minis — the app's only online feature,
backed by the Cloudflare Worker below. Optional: without a configured API the
tab shows a gated sample experience.

```
challenge_boards/
├── domain/
│   ├── models/challenge_models.dart             # Pure data classes (package:meta, no Flutter)
│   ├── repositories/…                           # Board / profile / result repository interfaces
│   └── services/
│       ├── challenge_solve_submission_mapper.dart  # Completion → submission (eligibility gate)
│       └── challenge_result_submitter.dart      # Outbox-backed submit-or-queue with flush
├── data/
│   ├── repositories/
│   │   ├── api_challenge_repository.dart        # Real backend (implements all three interfaces)
│   │   └── sample_challenge_repository.dart     # No-backend sample/gated experience
│   └── services/
│       ├── challenge_api_config.dart            # CHALLENGE_API_ENV / CHALLENGE_API_BASE_URL resolution
│       ├── challenge_board_api.dart             # Dio HTTP client (bootstrap-on-demand auth)
│       ├── challenge_identity_store.dart        # Token in SecureKeyValueStore; recovery bundle in DB
│       └── challenge_result_outbox.dart         # Offline result queue (app_settings, never synced)
├── presentation/…                               # Tab, board detail, sheets, avatar widgets
└── sample/sample_data.dart                      # Sample-mode fixtures
```

Identity model: anonymous player, bearer token in platform secure storage
(device-local by design), recovery bundle in the app database so it survives
OS backup and syncs via the user's own cloud (see `docs/privacy.md`).

---

## Backend: Challenge Boards Worker

The only server component (`crosscue/backend/challenge_boards/`):
Cloudflare Workers + D1, split into feature modules with `index.ts` as the
router:

```
src/
├── index.ts          # Routing + scheduled retention job
├── players.ts        # Bootstrap/restore/profile/avatar/auth/deletion
├── boards.ts         # Board lifecycle + invite flows
├── results.ts        # Honor-system result submission (bounded sanity checks)
├── leaderboards.ts   # Weekly/lifetime aggregation + ranking
├── membership.ts     # Membership lookups, invite verification, audit events
├── retention.ts      # 14-day board_events purge (daily cron)
└── http/util/validation/constants/types.ts     # Shared plumbing
```

Secrets (auth tokens, recovery secrets, invite codes) are stored only as
SHA-256 hashes; schema lives in numbered `migrations/`. Trust model and
endpoint contracts: [`API.md`](crosscue/backend/challenge_boards/API.md);
environments, migrations, and deploy flow: `DEPLOYMENT.md` ("Backend:
Challenge Boards Worker").

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

**Dynamic color + brand reconciliation (#112).** `AppTheme.light/dark` use the
system dynamic scheme (Material You on Android 12+; iOS via `dynamic_color`) as
the *base* when present, then apply Crosscue's brand roles
(`primary`/`surface`/`error` etc.) on top via `_brandLight`/`_brandDark` —
applied on **both** the dynamic and seeded-fallback paths, so the system accent
can never replace brand identity on key roles (it previously could on Android
12+, producing a half-dynamic look that clashed with the brand-fixed tokens in
`_build`). The dynamic base still harmonizes the roles we don't override. On
iOS, `dynamic_color` returns `null` in practice (no global user accent like
Android), so iOS always lands on the brand fallback — verified on the iOS 17
simulator (`lightDynamic`/`darkDynamic` both null; see the debug log in
`app.dart`).

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
| `/settings/sync` | Nested under `/settings` | `SyncSettingsScreen` |
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
  for settings) behind a platform-pluggable `SyncTransport`. See
  [`docs/architecture/sync-design.md`](docs/architecture/sync-design.md).
  Sync ships **opt-in (off by default)** — enabled from the onboarding sync
  step or Settings; there is no default-on flip. The remaining work is
  operational platform setup (iCloud entitlement / Google Drive OAuth) plus a
  two-device soak, documented in the sync setup guides under
  `docs/architecture/`.

- **Sync transports + UI shipped (May–Jun 2026)**: The iCloud transport
  (`ICloudSyncTransport`, #9 Phase 2) and the Settings + onboarding opt-in UI
  (#142) shipped, followed by the Google Drive transport
  (`GoogleDriveSyncTransport`, #145) and Android sign-in wiring (#157). The
  transport interface gained `signIn()` + `supportsInteractiveSignIn` so the
  orchestrator's `enable()` can drive an interactive Google prompt while iCloud
  stays ambient. User-facing copy is platform-generic via
  `core/sync/sync_service_copy.dart` ("iCloud" on iOS, "Google Drive" on
  Android). iCloud is live; Android sync stays inert until the Google Cloud
  OAuth clients exist (see
  [`docs/architecture/sync-googledrive-setup.md`](docs/architecture/sync-googledrive-setup.md)).

- **Widget background refresh (#175, Jun 2026)**: Best-effort daily refresh of
  the home-screen widget's "today" tile for users who don't open the app —
  iOS `BGAppRefreshTask` + Android WorkManager via the `workmanager` plugin and
  a single Dart callback (`core/background/widget_refresh_scheduler.dart`). The
  headless callback stands up its own `ProviderContainer` and runs the existing
  `attemptIfNeeded()` + `HomeWidgetService.refresh()`; it reads settings via the
  repository, never the boot-throwing `bootSettingsProvider`. Scheduled
  post-first-frame (no cold-start impact), idempotent, and a no-op off-device.
  Explicitly *not* an observer (the two-observer rule still holds — it runs in a
  separate isolate). Best-effort by design: iOS controls actual cadence. Setup +
  caveats in [`docs/architecture/ios-widget-setup.md`](docs/architecture/ios-widget-setup.md).
