# Crosscue — Implementation Plan

All research is resolved. This document translates the research into ordered implementation tasks. Each sprint builds on the previous one; do not start a sprint until the prior sprint's acceptance criteria pass.

Research topic references are abbreviated: **#N** = `research/topic-0N-*.md`.

---

## Sprint 1 — Foundation

**Goal:** A runnable Flutter app with empty screens, wired navigation, and a working Drift database.

### Tasks

1. **Scaffold project**
    - `flutter create --org com.crosscue crosscue`
   - Create the full `lib/` directory tree from **#12** as empty placeholder files
   - Add `# Generated — do not edit` to `.gitattributes` for `*.g.dart` / `*.freezed.dart`

2. **Add dependencies**
   - Copy `pubspec-starter.yaml` content into `pubspec.yaml`; run `flutter pub get`
   - Confirm `build_runner` watch task is runnable

3. **Core utilities**
   - `lib/core/utils/result.dart` — `Result<T, E>`, `Ok`, `Err`
   - `lib/features/solve/domain/models/enums.dart` — `Direction`, `CellState`, `PuzzleStatus`, `EntryMode`, `PuzzleFormat`, `SourceType`

4. **Drift schema — initial migration**
   - Tables: `sources`, `puzzles`, `clues`, `solve_sessions`, `cell_progress`, `app_settings`
   - All columns from **#02**, all stats/streak fields from **#15**, all pause fields from **#17 §4**
   - Sync-readiness columns from **#09**: `device_id`, `created_at`, `updated_at`, `is_synced`, `sync_version` on `solve_sessions`; `updated_at` on `cell_progress`
   - `solve_sessions.status` TypeConverter: `not_started | in_progress | completed | revealed`
   - `LicenseStatus` TypeConverter: camelCase enum ↔ snake_case DB string (see architecture doc)
   - Indexes from **#02**
   - Generate per-install `device_id` UUID in `app_settings` on first launch

5. **Core providers**
   - `AppDatabase` Drift class (`@DriftDatabase`)
   - `appDatabaseProvider`, `noOpSyncAdapterProvider`, `freeEntitlementServiceProvider` in `core/providers/core_providers.dart`
   - `NoOpSyncAdapter` in `core/sync/`
   - `FreeEntitlementService` in `core/entitlement/`

6. **Routing + shell**
   - `Routes` constants in `lib/core/routing/routes.dart`
   - `AppShell` in `lib/core/routing/app_shell.dart` — `NavigationBar` with 4 tabs
   - `appRouterProvider` GoRouter in `lib/core/routing/app_router.dart`
   - `hasSeenOnboardingProvider` as `FutureProvider<bool>` reading `has_seen_onboarding` from `app_settings`
   - `MaterialApp.router` wired in `app.dart`
   - Onboarding redirect: if `has_seen_onboarding == false`, redirect to `/onboarding`

7. **Screen stubs**
   - All 7 screens as empty `Scaffold(body: Center(child: Text('<ScreenName>')))` — enough to smoke-test navigation

8. **Theme**
   - `AppTheme` light + dark in `core/theme/app_theme.dart`
   - `CrosswordTheme` extension with color tokens (correct/incorrect/highlight/focus) from **#10**
   - `dynamic_color` wrapper in `app.dart` for Material You on Android 12+

**Sprint 1 acceptance criteria:**
- App launches, shows Home tab
- All 4 tab switches work without crash
- `/onboarding` appears on first launch; does not appear after `has_seen_onboarding` is set to `true` in `app_settings`
- Drift database file created on device; no migration errors in logs

---

## Sprint 2 — Import Pipeline

**Goal:** A user can import a `.puz` or `.ipuz` file and have it stored in Drift. No solve UI yet — the puzzle just lands in the database.

### Tasks

9. **Domain models**
   - `Grid<T>` — `List<T> cells`, `int width`, `int height`, `T cell(int row, int col)` (architecture doc)
   - `FocusPosition` — Freezed `(int row, int col)` (architecture doc)
   - `SolutionCell` — Freezed (architecture doc)
   - `CellProgress` — Freezed with `isPencil` field (architecture doc)
   - `PuzzleMetadata` — Freezed (architecture doc; no `sourceFormat` field — that lives on `Puzzle`)
   - `Clue` — Freezed: `number`, `direction`, `text`, `answerLength`, `startRow`, `startCol`, `sortOrder` (architecture doc)
   - `Puzzle` — Freezed: `id`, `meta`, `grid`, `acrossClues`, `downClues`, `sourceFormat` (architecture doc)

10. **Parsers**
    - `PuzzleParser` abstract interface + `ParseError` enum (`lib/features/import/data/parsers/`)
    - `PuzParser` — header, CRC-16, grid, string section, GRBS/RTBL/GEXT extensions (**#14**)
    - `IpuzParser` — JSON decode, dimensions, puzzle/solution/clues (**#14**)
    - `JpzParser` stub — `return Err(ParseError.unsupportedFormat)` placeholder
    - `generateLocalPuzzleId` — SHA-256 of canonical content via `crypto` (**#14**)
    - Both parsers set `meta.sourceId = 'local_import'`

11. **Parser tests** (write alongside parsers)
    - Fixtures in `test/fixtures/puzzles/` per **#14** requirements
    - Tests for all `ParseError` variants + happy paths

12. **Puzzle DAO + Import Repository**
    - `PuzzleDao` in `features/import/data/daos/` — insert puzzle, clues, initial session atomically
    - `ImportRepositoryImpl` — file extension routing → parser → Drift insert → `ImportFailure` on error
    - Duplicate detection via `puzzles.checksum` unique index

13. **Import screen + notifier**
    - `ImportScreen` with three-zone layout from **#17 §3**
    - `ImportNotifier` — file picker → parse → insert → navigate to `/solve/:puzzleId` on success
    - Import error bottom sheet from **#16**
    - "Name this puzzle" dialog when title + publish date are both absent

14. **Source registry**
    - `PuzzleSource` abstract class + `SourceRegistry` with `licenseStatus` guard
    - `LocalImportSource` — `licenseStatus: LicenseStatus.userImport`
    - Register `LocalImportSource` in app startup

**Sprint 2 acceptance criteria:**
- Import a valid `.puz` file → puzzle row appears in `puzzles` table, clue rows in `clues`
- Import a valid `.ipuz` file → same
- Import a malformed file → friendly error bottom sheet, no crash
- Import the same file twice → no duplicate row (idempotent via checksum)
- Navigate to `/import` from Home stub and back

---

## Sprint 3 — Solve Engine

**Goal:** The puzzle engine processes cell entry, navigation, check/reveal, and completion. No UI beyond a basic scaffold — this sprint is mostly pure Dart logic.

### Tasks

15. **PuzzleEngine (pure logic, no Flutter deps)**
    - Cell entry: place letter, advance focus per `MovementStrategy` (**#11**)
    - `DefaultMovementStrategy` + `SkipFilledStrategy` (**#11**, architecture doc)
    - Direction toggle on double-tap / ClueBar tap (**#17 §8**)
    - Delete / backspace behavior (**#11**)
    - Check letter / word / puzzle → `CellState` updates (**#11**)
    - Reveal letter / word / puzzle → `wasRevealed`, `cleanSolveEligible = false` (**#11**)
    - Completion detection: all non-black cells filled + correct → derive `PuzzleStatus` and `completion_type` (**#11**, **#15**)
    - Undo/redo: parallel history stack, max depth 20 (architecture doc)

16. **PuzzleState**
    - Confirm Freezed class matches architecture doc (all fields including `isPaused`, `elapsed`)
    - All engine operations return a new `PuzzleState` — no mutation

17. **PuzzleNotifier (AsyncNotifier<PuzzleState>)**
    - Load puzzle + latest session from Drift on init
    - Autosave after every cell change (debounce ~500 ms)
    - Persist `focus_row`, `focus_col`, `direction`, `elapsed_ms`, `is_paused`
    - Timer: increment `elapsed` every second while `!isPaused`
    - `AppLifecycleListener` auto-pause on background; resume overlay on foreground (**#17 §4**)
    - Pause/resume toggle (**#17 §4**)
    - Completion: write `completion_type`, `completed_at`, `solved_date_local`, `solved_timezone` to `solve_sessions` (**#15**)

18. **SolveSessionDao** — resume session, update cell progress, mark complete

**Sprint 3 acceptance criteria:**
- `PuzzleEngine` unit tests: letter entry, advance, direction toggle, check/reveal, completion detection, undo/redo
- `PuzzleNotifier` integration test: load puzzle → enter all correct answers → status transitions to `solved`
- Autosave: kill app mid-solve, relaunch → session restored to exact state
- Backgrounded app pauses timer; returns to foreground and shows resume overlay

---

## Sprint 4 — Solve UI

**Goal:** A fully interactive solve screen — grid, clues, keyboard, completion sheet.

### Tasks

19. **CrosswordGridPainter**
    - `drawBlackCells`, `drawCellNumbers`, `drawUserLetters`, `drawFocusHighlight`, `drawWordHighlight`, `drawCrossHighlight`, `drawVerificationState`
    - `semanticsBuilder` — per-cell `SemanticsNode` with label, value, checked/revealed state (**#03**)
    - `GridMetrics` for shared geometry between paint and semantics

20. **CrosswordGrid widget**
    - Wraps `CustomPaint(painter: CrosswordGridPainter(...))`
    - `InteractiveViewer`: `minScale: 1.0`, `maxScale: 3.0`, `TransformationController`
    - Double-tap to reset zoom (**#17 §13**)
    - Focus-follow: `TransformationController` animates to keep active cell visible
    - `TransformationController.addListener` → `markNeedsSemanticsUpdate()` after every transform (**#17 §13**)

21. **ClueBar**
    - Shows active clue text with direction indicator (↔ / ↕ prefix) (**#17 §8**)
    - Tap toggles direction if cell has perpendicular word

22. **CluePanel (clue list)**
    - Scrollable list; active clue highlighted with `primaryContainer`
    - `ScrollController.animateTo` (150 ms ease-out) to keep active clue visible (**#17 §9**)
    - Tap navigates focus to first unfilled cell of that clue

23. **Custom keyboard**
    - Alpha keys A–Z, Delete, Check (→ `checkWord`), directional arrows (**#17 §6**)
    - Matches system light/dark theme

24. **SolveScreen assembly**
    - Portrait: AppBar → ClueBar → notes banner → Grid → CluePanel
    - AppBar: back button, title, timer (tap to pause/resume) (**#17 §4**)
    - Puzzle notes dismissible info banner (**#17 §16**)
    - Overflow menu (⋮): full spec from **#17 §11** including Puzzle info (if notes non-empty)
    - `PopScope(canPop: false)` back dialog if any guesses entered (**#17 §1**)
    - Load failure state (**#17 §14**)
    - Post-completion read-only state (**#17 §10**)

25. **CompletionStatsSheet**
    - `DraggableScrollableSheet` with solve label, time, PB comparison, streak, share/view/next actions (**#17 §2**)
    - Confetti animation via `confetti` package
    - Completion haptic pulse via `vibration` package

26. **Accessibility pass**
    - TalkBack traversal order, announcement strings (**#03**)
    - Check/reveal/revealed cell value announcements

**Sprint 4 acceptance criteria:**
- Import a puzzle → tap → solve screen renders correctly
- Enter all correct answers → completion sheet appears with correct stats
- Screen reader: navigate cells, hear clue labels, hear check/reveal state
- Zoom to 2× → double-tap resets → focus cell is centered
- Kill app mid-solve → resume from exact cell focus and timer value

---

## Sprint 5 — First-Run Experience

**Goal:** A new user lands on onboarding, completes it, arrives at an empty Home, imports their first puzzle.

### Tasks

27. **Onboarding screen**
    - 5×5 const mock grid: ACE across (row 0 cols 0–2), END down (col 2 rows 0–2) (**#17 §19**)
    - Three-step card overlay; steps and completion triggers from **#17 §7**
    - "Import your first puzzle" CTA on completion → `/import`
    - Write `has_seen_onboarding = true` on completion/skip → router redirect drops onboarding

28. **Home screen**
    - Empty state: import FAB + explanatory copy (**#16**)
    - Streak banner when streak > 0
    - In-progress card for active puzzle (if any)
    - Import FAB always visible in Phase 1

29. **Settings screen** (full implementation)
    - Five-section layout from **#17 §12**
    - All settings keys from architecture Settings Inventory backed by `app_settings` DAO
    - Theme toggle: live-applies via `SettingsNotifier` → `appThemeProvider`
    - Crash reporting opt-in toggle (default off) (**#05**)
    - Export: share `.db` file via `share_plus`
    - Import: file picker for `.db` restore with "current data will be overwritten" warning
    - Delete all data: confirmation dialog → truncate all tables
    - About Crosscue: version, licenses, privacy policy link

**Sprint 5 acceptance criteria:**
- Fresh install: onboarding appears, completes, arrives at empty Home
- Reinstall with existing `app_settings`: onboarding skipped
- Theme toggle applies immediately without restart
- Export `.db` → fresh install → import `.db` → solve history restored

---

## Sprint 6 — Archive + Stats

**Goal:** Users can browse past puzzles and see their solve statistics.

### Tasks

30. **Archive screen**
    - Vertical list view (no calendar in Phase 1) (**#17 §5**)
    - List item: status icon (○ ◑ ✓ ★), title, source/date, status label + time
    - Latest-session-per-puzzle SQL query (orphan suppression) (**#17 §20**, **#02**)
    - Sort picker: import date / puzzle date / title (**#17 §5**)
    - Filter chips: All / In Progress / Completed / Not Started (**#17 §5**)
    - Long-press → delete with cascade-delete confirmation (**#17 §17**)
    - Tap → `/solve/:puzzleId`

31. **Stats screen**
    - `StatsRepository` + `StatsService` implementing streak algorithm from **#15**
    - `currentStreak`, `longestStreak` using `solved_date_local` strings (**#15**)
    - Completion counts, average time, personal best per grid size (**#15**)
    - Streak milestone tracking in `streak_milestones_shown` (**#15**)
    - Milestone celebration notification (immediate, post-completion) (**#06**, **#15**)
    - Empty states for < 3 puzzles

**Sprint 6 acceptance criteria:**
- Archive shows all imported puzzles with correct status
- Restart puzzle → old session preserved in DB, Archive shows new in-progress session only
- Delete puzzle → cascade removes clues, sessions, cell_progress; streak recalculates
- Stats screen: solve a clean puzzle → streak increments; reveal puzzle → streak unchanged

---

## Sprint 7 — Polish + Store Prep

**Goal:** App is production-ready and submittable to Play Store.

### Tasks

32. **Crash reporting**
    - Integrate `sentry_flutter` (or `firebase_crashlytics`) in `CrashReporter` implementation (**#05**)
    - Initialize only when `crash_reporting_enabled == true` in settings
    - Never log puzzle content, clue text, solution, or user guesses (**#05**)

33. **Haptics + animations**
    - Cell fill scale pulse (~80 ms) via `flutter_animate`
    - Word completion green flash (~300 ms) via `flutter_animate`
    - Reveal cell flip (~400 ms) via `flutter_animate`
    - Completion haptic pulse via `vibration`

34. **Shimmer loading states**
    - Archive list shimmer when loading > 300 ms
    - Stats screen shimmer

35. **Splash screen**
    - Configure `flutter_native_splash`: background `#1565C0`, centered app icon (**#17 §18**)
    - Run `dart run flutter_native_splash:create`

36. **Android Auto Backup**
    - `AndroidManifest.xml`: `android:allowBackup="true"`, `android:hasFragileUserData="true"` (**#09**, **#18**)
    - `res/xml/backup_rules.xml`: include `crossword.db`, exclude WAL/SHM (**#09**)

37. **Security hardening**
    - File size cap (5 MB) and extension/MIME check before parsing (**architecture Security section**)
    - `android:usesCleartextTraffic="false"` in manifest (enforcing secure connections for approved network sources)
    - Confirm no puzzle content reaches crash reporter (**#05**)

38. **Privacy policy**
    - Publish policy at stable URL (e.g. `https://example.com/crosscue/privacy`) (**#18**)
    - Insert correct crash reporter vendor name and privacy link into published policy
    - "About Crosscue" settings row links to the published URL

39. **Play Store submission**
    - Complete Data Safety form using answers from **#18**
    - Set `targetSdkVersion 35` in `build.gradle`
    - Generate signed release APK / AAB
    - Store listing: description, screenshots, privacy policy URL
    - Add `flutter_native_splash` output files to version control

40. **Open Source Licenses**
    - Run `flutter pub run flutter_oss_licenses` and wire output into About screen (**architecture license section**)

**Sprint 7 acceptance criteria:**
- App installs from Play Store internal track without rejection
- Crash reporter fires only when toggled on; no puzzle content in payloads
- Privacy policy URL resolves publicly
- Data Safety form submitted and approved

---

## Deferred to Phase 2

The following are explicitly out of scope for Phase 1. Do not start these until the Play Store version is live and has real users.

- iOS target (Flutter makes this low-effort when the time comes)
- Local notifications / reminders (**#06**)
- Network puzzle sources (legal clearance required first — **#07**)
- User statistics calendar view (**#10**)
- JSON export format (**#09**)
- RevenueCat / support IAP (**#04**)
- `flutter_local_notifications` + `flutter_timezone` + `timezone` packages
- `in_app_purchase` package

---

## Key Cross-Sprint Dependencies

| Later task | Depends on |
|------------|-----------|
| Import screen (13) | Domain models (9) |
| PuzzleEngine (15) | Domain models (9) |
| PuzzleNotifier (17) | PuzzleEngine (15) + SolveSessionDao (18) |
| CrosswordGridPainter (19) | PuzzleState (16) |
| SolveScreen (24) | Painter (19) + ClueBar (21) + Keyboard (23) + Notifier (17) |
| Archive list (30) | SolveSessionDao (18) |
| Stats screen (31) | Drift schema streak fields from Sprint 1 |
| Crash reporting (32) | Settings screen (29) for opt-in toggle |
