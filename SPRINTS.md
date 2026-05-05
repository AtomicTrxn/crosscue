# Sprint Tracker — Crosscue

Status key: ✅ Done · 🔄 In Progress · ⬜ Planned · ⏸ Deferred

---

## Sprint 1 — Project Scaffold ✅

**Goal:** Runnable shell app with routing, theming, and empty DB.

| Task | Status | Key files |
|------|--------|-----------|
| Flutter project (`com.crosscue.crosscue`) | ✅ | `pubspec.yaml`, `main.dart` |
| Material 3 theme + DynamicColor | ✅ | `core/theme/app_theme.dart`, `core/theme/crossword_theme.dart` |
| Drift DB + all 6 tables | ✅ | `core/database/` |
| go_router with 4-tab shell | ✅ | `core/routing/` |
| Stub screens (Archive, Stats, Settings, Onboarding) | ✅ | `features/*/presentation/screens/` |
| `Result<T,E>` utility type | ✅ | `core/utils/result.dart` |
| Entitlement + sync stubs | ✅ | `core/entitlement/`, `core/sync/` |

---

## Sprint 2 — Puzzle Import Pipeline ✅

**Goal:** User can pick a `.puz` or `.ipuz` file and see it in the home list.

| Task | Status | Key files |
|------|--------|-----------|
| Domain models (Puzzle, PuzzleMetadata, Clue, SolutionCell, CellProgress, FocusPosition) | ✅ | `features/solve/domain/models/` |
| `Grid<T>` plain Dart class | ✅ | `solve/domain/models/grid.dart` |
| `ParseError` enum | ✅ | `import/domain/models/parse_error.dart` |
| `PuzzleParser` abstract interface | ✅ | `import/domain/repositories/puzzle_parser.dart` |
| `.puz` binary parser (rebus GRBS/RTBL, circles GEXT, clue numbering) | ✅ | `import/data/parsers/puz_parser.dart` |
| `.ipuz` JSON parser | ✅ | `import/data/parsers/ipuz_parser.dart` |
| `GridSerializer` (Grid ↔ JSON for DB) | ✅ | `import/data/daos/grid_serializer.dart` |
| `PuzzleDao` (insert/get/delete, duplicate check) | ✅ | `import/data/daos/puzzle_dao.dart` |
| `ImportRepositoryImpl` (parse + persist orchestration) | ✅ | `import/data/repositories/import_repository_impl.dart` |
| `ImportNotifier` + sealed `ImportState` | ✅ | `import/presentation/notifiers/import_notifier.dart` |
| `ImportScreen` UI | ✅ | `import/presentation/screens/import_screen.dart` |
| `HomeScreen` puzzle list + `puzzleListProvider` | ✅ | `home/presentation/screens/home_screen.dart` |
| Parser unit tests with fixture | ⏸ | Deferred to Sprint 8 |
| `PuzzleSource` / `SourceRegistry` abstraction | ⏸ | Deferred to Sprint 8 |

**Known constraints resolved in this sprint:**
- Android file picker: `FileType.any` required (`.puz`/`.ipuz`/`.jpz` have no registered MIME types)
- Freezed 3.x: single-factory classes must be `abstract class`

---

## Sprint 3 — Interactive Solve Screen ✅

**Goal:** User can open a puzzle and solve it with a working keyboard, timer, and clue panel.

| Task | Status | Key files |
|------|--------|-----------|
| `SolveState` plain immutable class | ✅ | `solve/presentation/notifiers/solve_state.dart` |
| `SolveNotifier` (AsyncNotifier family, timer, tap, input, backspace, completion) | ✅ | `solve/presentation/notifiers/solve_notifier.dart` |
| `CrosswordGridPainter` (CustomPainter, 3-tier highlight, numbers, circles, letters) | ✅ | `solve/presentation/widgets/crossword_grid_painter.dart` |
| `CrosswordGrid` (tap focus, physical kbd, soft kbd via hidden TextField) | ✅ | `solve/presentation/widgets/crossword_grid.dart` |
| `CluePanel` (active + cross clue) | ✅ | `solve/presentation/widgets/clue_panel.dart` |
| `SolveScreen` (AppBar, timer, completion banner) | ✅ | `solve/presentation/screens/solve_screen.dart` |

**Bugs fixed in this sprint:**
- `Stream<int>.periodic` without computation arg crashes in null-safe Dart → `(i) => i`
- Shared `FocusNode` between `Focus` widget and `TextField` child → "child into parent of itself" crash → attach `onKeyEvent` to `FocusNode` directly in `initState`, remove outer `Focus` widget

---

## Sprint 4 — Solve Persistence ✅

**Goal:** Progress is saved to DB. Resuming a puzzle restores the exact state.

**Read before starting:** [topic-02](research/topic-02-drift-database-schema.md) (`solve_sessions` + `cell_progress` schema detail), [topic-11](research/topic-11-game-mechanics-feedback.md) (pause/resume rules), [topic-17](research/topic-17-ux-missing-details.md) §4 (timer pause/background behaviour)

| Task | Status | Notes |
|------|--------|-------|
| `SolveSessionDao` — create/update session, save cell progress | ✅ | `solve/data/daos/solve_session_dao.dart` |
| `SolveNotifier` auto-save on every cell change (debounced ~500 ms) | ✅ | 500 ms `Timer` debounce in `_scheduleSave()` |
| Resume detection in `build()` — load existing session if found | ✅ | `SolveRepositoryImpl.createOrResumeSession()` |
| Pause timer when app goes to background (`AppLifecycleListener`) | ✅ | `WidgetsBindingObserver` in `SolveScreen` |
| Elapsed time persistence (`solve_sessions.elapsed_ms`) | ✅ | Restored in `build()`; saved on every autosave |
| Focus position persistence (`focus_row`, `focus_col`, `direction`) | ✅ | Restored in `build()`; saved on every autosave |

---

## Sprint 5 — Check & Reveal ✅

**Goal:** User can check or reveal a letter, word, or the full grid.

**Read before starting:** [topic-11](research/topic-11-game-mechanics-feedback.md) (check/reveal/hint rules, CellState transitions, mistake counting), [topic-17](research/topic-17-ux-missing-details.md) §3 (keyboard Check key scope), §8 (ClueBar tap-to-toggle)

| Task | Status | Notes |
|------|--------|-------|
| `SolveNotifier.checkCell/Word/Grid()` — set `CellState.checkedCorrect/Incorrect` | ✅ | |
| `SolveNotifier.revealCell/Word/Grid()` — set `CellState.revealed`, fill letter | ✅ | `revealPuzzle` sets `status = revealed` (no streak) |
| Update `PuzzleStatus` to `solvedWithHelp` on completion with assistance | ✅ | Derived from `usedCheck`/`usedReveal` flags |
| Check/Reveal menu in `SolveScreen` AppBar | ✅ | `⋮` overflow menu; Reveal puzzle has confirmation dialog |
| `solve_sessions.check_count`, `reveal_count`, `used_check`, `used_reveal` tracking | ✅ | Persisted on every autosave; restored on resume |
| Set `solve_sessions.clean_solve_eligible = false` when check/reveal used | ✅ | Set on first reveal action |

---

## Sprint 6 — Onboarding, Settings & Polish ✅

**Goal:** Real onboarding flow, persistent settings, accessibility pass, app polish.

**Read before starting:** [topic-16](research/topic-16-first-run-phase1.md) (onboarding flow, sample puzzle policy), [topic-17](research/topic-17-ux-missing-details.md) §7 (onboarding format), §10 (post-completion review), §19 (mock grid design), [topic-10](research/topic-10-design-ux-research.md) (animations, haptics, completion feedback), [topic-03](research/topic-03-canvas-accessibility.md) (CustomPainter TalkBack semantics)

| Task | Status | Notes |
|------|--------|-------|
| `AppSettingsDao` — store onboarding flag, theme preference, haptics | ✅ | `core/settings/app_settings_dao.dart` |
| `AppSettingsRepository` — typed helpers for all settings | ✅ | `core/settings/app_settings_repository.dart` |
| `hasSeenOnboardingProvider`, `ThemeModeNotifier`, `HapticsEnabledNotifier` | ✅ | `core/settings/settings_providers.dart` |
| `OnboardingScreen` real 3-step interactive flow (mock 5×5 grid) | ✅ | `features/onboarding/presentation/screens/onboarding_screen.dart` |
| `SettingsScreen` — theme SegmentedButton, haptics toggle, clear data | ✅ | `features/settings/presentation/screens/settings_screen.dart` |
| Completion bottom sheet (`DraggableScrollableSheet`) with stats | ✅ | Replaces `MaterialBanner` in `solve_screen.dart` |
| Haptic feedback on cell tap + completion + long-press | ✅ | `flutter/services.dart` `HapticFeedback`; reads `hapticsEnabledProvider` |
| Long-press grid cell → contextual Check/Reveal popup (ISSUES #2) | ✅ | `crossword_grid.dart` `onLongPressStart` → `showMenu` |
| Keyboard overlay — grid no longer shifts on keyboard show/hide (ISSUES #4) | ✅ | `resizeToAvoidBottomInset: false`; `viewInsets.bottom` pad on clue panel |
| App icon + splash screen | ⏸ | Deferred to Sprint 7 |
| CustomPainter accessibility semantics (TalkBack) | ⏸ | Deferred to Sprint 7 (topic-03) |

---

## Sprint 7 — Archive & Stats ✅

**Goal:** Solved puzzles are browsable; basic solving stats are displayed.

**Read before starting:** [topic-15](research/topic-15-streak-stats-algorithm.md) (streak algorithm, completion types, personal bests, milestones), [topic-17](research/topic-17-ux-missing-details.md) §5 (Archive Phase 1 list view), §20 (orphan session handling)

| Task | Status | Notes |
|------|--------|-------|
| `ArchiveScreen` — all puzzles with latest session status, sort/filter chips, long-press delete | ✅ | `archive/presentation/screens/archive_screen.dart`; uses `archiveEntriesProvider` |
| `StatsScreen` — streak, solve counts, avg times, personal bests, completion rate | ✅ | `stats/presentation/screens/stats_screen.dart`; uses `statsDataProvider` |
| `StatsDao` — join sessions + puzzles; streak dates; session count | ✅ | `stats/data/daos/stats_dao.dart`; returns typed `CompletedSessionStat` records |
| Streak algorithm using `solved_date_local` (current + longest) | ✅ | Implemented in `StatsRepositoryImpl`; yesterday-not-yet-today rule applied |
| `CompletionType` breakdown (clean / checked / hinted / revealed) | ✅ | Derived from `solve_sessions.completion_type`; all four shown in Stats screen |
| `ArchiveRepositoryImpl` — latest session per puzzle (orphan-safe) | ✅ | `SolveSessionDao.getLatestSession()`; N+1 acceptable for Phase 1 |
| Personal bests by grid size (mini ≤7×7, 15×15, 21×21) | ✅ | Clean solves only per topic-15 |
| `publishDate` added to `PuzzleMetadata` | ✅ | Enables sort-by-puzzle-date in Archive |
| Sort (import date / puzzle date / title) + filter chips (All / In Progress / Completed / Not Started) | ✅ | Client-side in `ArchiveScreen` state |
| Single-puzzle long-press delete with confirmation dialog | ✅ | Cascades to clues/sessions/cell_progress via FK; invalidates `archiveEntriesProvider` |

---

## Sprint 8 — Parser Tests & Source Registry ✅

**Goal:** Hardened parsers with regression tests; foundation for future puzzle sources.

**Read before starting:** [topic-14](research/topic-14-puzzle-parser-spec.md) (field-by-field parser spec, test fixture requirements), [topic-01](research/topic-01-puzzle-source-endpoints.md) (source endpoints and downloader strategy), [topic-07](research/topic-07-legal-tos-puzzle-sources.md) (**legal guardrail — read before any source work**)

| Task | Status | Notes |
|------|--------|-------|
| `.puz` parser unit tests with known-good BEQ fixture | ✅ | `PuzFixtureBuilder` synthesizes binary fixtures in memory; 25 tests |
| `.ipuz` parser unit tests | ✅ | 22 tests covering golden path, rebus, object clues, error cases |
| `PuzzleSource` abstract class | ✅ | Deferred from Sprint 2; `lib/features/import/domain/repositories/puzzle_source.dart` |
| `SourceRegistry` with `LicenseStatus` enforcement | ✅ | Throws `SourceRegistrationException` for `prohibited` sources; excludes `needsReview` from `enabledSources` |
| `LocalImportSource` wrapping existing parsers | ✅ | `id='local_import'`, `licenseStatus=userImport`, always enabled |
| Parser hardening | ✅ | 5 MB size guard + `fileTooLarge` error; fixed GEXT circle bit (`0x80` → `0x10`) |

**Test results:** 78/78 passing (`source_registry_test`: 22, `ipuz_parser_test`: 22+, `puz_parser_test`: 25+)

---

## Deferred / Post-MVP

| Item | Notes |
|------|-------|
| Pencil mode | `EntryMode.pencil` enum already defined; `cell_progress.is_pencil` column exists |
| Rebus entry (multi-letter cells) | `EntryMode.rebus` defined; rebus parsed from `.puz` but not yet editable |
| Sync adapter (iCloud / Drive) | `SyncAdapter` interface + `NoOpSyncAdapter` stub in `core/sync/` |
| Subscription / entitlement | `EntitlementService` interface + `FreeEntitlementService` stub in `core/entitlement/` |
| iOS support | Phase 2; Android is Phase 1 target |
| Automated puzzle downloaders | Only for `LicenseStatus.openLicense` or `explicitPermission` sources |
