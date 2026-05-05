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
| App icon + splash screen | ⏸ | Deferred to Post-MVP |
| CustomPainter accessibility semantics (TalkBack) | ⏸ | Deferred to Post-MVP (topic-03) |

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

**Test results:** Current full suite 79/79 passing (`source_registry_test`, `ipuz_parser_test`, `puz_parser_test`, widget smoke test)

---

## Sprint 9 — Design Foundation ✅

**Goal:** Adopt the design handoff's token system and global Material styling without changing workflows.

**Read before starting:** [docs/design-implementation-plan.md](docs/design-implementation-plan.md), [design/README.md](design/README.md), [design/design_tokens.dart](design/design_tokens.dart), [design/app_theme.dart](design/app_theme.dart), [design/crossword_theme.dart](design/crossword_theme.dart)

| Task | Status | Notes |
|------|--------|-------|
| Commit `design/` handoff files | ✅ | Committed in f6523a1 — source of truth for visual references |
| Add `design_tokens.dart` under `lib/core/theme/` | ✅ | `CrosscueColors`, `CrosscueTypography`, `CrosscueSpacing` — all raw values |
| Update `AppTheme` global styling | ✅ | AppBar, nav bar, buttons, chips, dividers, list tiles, full text theme, `TimerStyle` extension |
| Expand `CrosswordTheme` tokens | ✅ | 12 → 22 tokens; renamed fields; added ClueBar, keyboard, gridEmpty, gridOuterBorder; callers updated |
| Dynamic Color policy | ✅ | `CrosswordTheme.of(scheme)` uses only `scheme.brightness` — grid/clue/keyboard colors are fixed |
| Light + dark mode verification | ✅ | `flutter analyze` 0 issues; 79/79 tests passing (widget smoke test passes) |

**Key files changed:**
- `lib/core/theme/design_tokens.dart` — new
- `lib/core/theme/app_theme.dart` — full rewrite
- `lib/core/theme/crossword_theme.dart` — expanded from 12 to 22 tokens, new field names
- `lib/features/solve/presentation/widgets/crossword_grid_painter.dart` — updated to new token names; outer border now `gridOuterBorder`; `gridEmpty` replaces `Colors.white`; `cellText` used for all letter states
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` — updated to new token names

---

## Sprint 10 — Solve Redesign ✅

**Goal:** Rebuild the solve experience to match the high-fidelity design references.

**Read before starting:** [docs/design-implementation-plan.md](docs/design-implementation-plan.md), [design/Crosscue Design Review.html](design/Crosscue%20Design%20Review.html)

| Task | Status | Notes |
|------|--------|-------|
| Compact 48dp solve app bar | ✅ | `_SolveAppBar` PreferredSizeWidget; centred title, timer + ⋮ trailing |
| Add `ClueBar` above grid | ✅ | `clue_bar.dart`; direction arrow ↔/↕, clue number, clue text; tap calls `toggleDirection()` |
| Full-width grid layout | ✅ | `cellSize = maxWidth / puzzle.width`; `CrosswordGrid` self-sizes height via `SizedBox` |
| Painter visual refresh | ✅ | Letter factor `0.62→0.52`, number factor `0.27→0.22` via `CrosscueTypography` tokens |
| Two-column clue panel | ✅ | `clue_panel.dart` rewritten; Across/Down `ListView` columns; active/cross bg; 150 ms auto-scroll |
| Custom QWERTY keyboard | ✅ | `crossword_keyboard.dart`; ⌫ delete, ✓ check-word; physical keyboard preserved via hidden TextField |
| 15x15 + mini layout QA | ✅ | analyze 0 issues · 79/79 tests · debug APK built |

**Key files changed:**
- `lib/features/solve/presentation/notifiers/solve_notifier.dart` — `toggleDirection()` method
- `lib/features/solve/presentation/screens/solve_screen.dart` — full layout rebuild
- `lib/features/solve/presentation/widgets/clue_bar.dart` — new
- `lib/features/solve/presentation/widgets/clue_panel.dart` — rewritten two-column
- `lib/features/solve/presentation/widgets/crossword_grid.dart` — full-width layout
- `lib/features/solve/presentation/widgets/crossword_grid_painter.dart` — design-token font factors
- `lib/features/solve/presentation/widgets/crossword_keyboard.dart` — new

---

## Sprint 11 — Home, Archive & Stats Redesign ⬜

**Goal:** Bring the primary tabs into the flat, dense design language while keeping the app local/offline-first.

**Read before starting:** [docs/design-implementation-plan.md](docs/design-implementation-plan.md), [design/Crosscue Design Review.html](design/Crosscue%20Design%20Review.html)

| Task | Status | Notes |
|------|--------|-------|
| Home redesign for local puzzles | ⬜ | Use "Current puzzle" / "Continue" model instead of publisher "Today" feed |
| Neutral sample/empty-state content | ⬜ | Do not use uncleared publisher names in production UI |
| Archive row/filter/sort refresh | ⬜ | Flat rows, semantic status icons, chip styling |
| Stats screen refresh | ⬜ | Flat sections, mono time values, no card-heavy layout |
| Import/source placement review | ⬜ | Downloader/source management belongs in Settings, not Home |

---

## Sprint 12 — Settings, Import & Onboarding Redesign ✅

**Goal:** Align secondary flows with the redesign and make Settings the home for import/source management.

**Read before starting:** [docs/design-implementation-plan.md](docs/design-implementation-plan.md), [ISSUES.md](ISSUES.md) #3, [research/topic-07-legal-tos-puzzle-sources.md](research/topic-07-legal-tos-puzzle-sources.md)

| Task | Status | Notes |
|------|--------|-------|
| Settings visual refresh | ✅ | Token spacing, flat rows, segmented theme control, haptics toggle, destructive action styling |
| Move import management into Settings | ✅ | Home no longer exposes import directly; local import and source management live under Settings |
| Add future source/downloader area | ✅ | Present as disabled/legal-guarded until a source is `openLicense` or `explicitPermission` |
| Import screen restyle | ✅ | Token spacing, local-only copy, Android `FileType.any` pipeline unchanged |
| Onboarding restyle | ✅ | Token spacing, refreshed mock grid/instruction sheet, neutral/local examples |
| Legal guardrail copy audit | ✅ | Production UI has no uncleared publisher names as built-in examples |

---

## Sprint 13 — Icon, Splash & Visual QA ⬜

**Goal:** Ship the app icon/splash polish and verify the redesigned UI end to end.

**Read before starting:** [docs/design-implementation-plan.md](docs/design-implementation-plan.md), [design/crosscue-icon.svg](design/crosscue-icon.svg), [design/Crosscue App Icon.html](design/Crosscue%20App%20Icon.html)

| Task | Status | Notes |
|------|--------|-------|
| Generate Android launcher icons | ⬜ | Use `design/crosscue-icon.svg` as final source |
| Update splash color/assets | ⬜ | Background `#0A2A6E` |
| Visual QA screenshots | ⬜ | Home, Solve 15x15, Solve mini, Archive, Stats, Settings, Onboarding, Import, completion sheet |
| Light/dark QA | ⬜ | Verify contrast and crossword readability |
| Final verification | ⬜ | `flutter analyze`, `flutter test`, debug APK build |

---

## Deferred / Post-MVP

| Item | Notes |
|------|-------|
| Pencil mode | `EntryMode.pencil` enum already defined; `cell_progress.is_pencil` column exists |
| Rebus entry (multi-letter cells) | `EntryMode.rebus` defined; rebus parsed from `.puz` but not yet editable |
| Sync adapter (iCloud / Drive) | `SyncAdapter` interface + `NoOpSyncAdapter` stub in `core/sync/` |
| Subscription / entitlement | `EntitlementService` interface + `FreeEntitlementService` stub in `core/entitlement/` |
| iOS support | Phase 2; Android is Phase 1 target |
| Automated puzzle downloaders | Only for `LicenseStatus.openLicense` or `explicitPermission` sources; management lives in Settings |
