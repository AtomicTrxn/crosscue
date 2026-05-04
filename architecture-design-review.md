# Crossword App — Architecture & Design Review

## Problem Statement

The crossword app landscape in 2026 is fragmented and stagnant:

- **The best free native Android solver (Robocrosswords) has been abandoned since 2018.** It runs on legacy Java, has no modern UX, and is slowly breaking as publisher sites change their HTML.
- **The best-designed crossword experience (NYT) is locked behind a subscription and a single content source.** Users who want variety — Guardian cryptics, LA Times, indie constructors — are left with inferior tools.
- **Web-first apps (Crosshare) don't deliver a native mobile experience.** No true offline play, no platform keyboard integration, no haptics, no home screen presence.
- **Free puzzle content exists in abundance but is inaccessible.** Dozens of high-quality free daily crosswords are published across the web with no single well-designed app to surface them.

The result: a daily crossword solver who isn't paying for NYT has no good option. They're either using a broken legacy app, a frustrating mobile web experience, or they've given up entirely.

**We are building the app that should exist:** a modern, native, multi-source crossword experience that is free to use, works offline, and treats the solver's time and attention with respect.

---

## Target Users

### Primary: The Daily Habit Solver
- Solves one crossword every day, usually during a commute, lunch break, or before bed
- May or may not subscribe to NYT — wants quality puzzles regardless
- Values: speed to puzzle, smooth keyboard input, progress saved automatically, satisfying completion feedback
- Frustration today: the free options feel cheap; the paid option is locked to one source

### Secondary: The Variety Seeker
- Wants access to different constructors and styles — LA Times, Guardian cryptics, indie puzzles
- Currently juggles multiple apps or browser bookmarks
- Values: a single place to find and solve puzzles from many sources
- Frustration today: no single app aggregates free quality content well

### Out of Scope (Phase 1)
- Puzzle constructors (building puzzles) — Phase 3
- Competitive/multiplayer solvers — Phase 3
- Children / educational use — not designed for

---

## What "Superior Experience" Means Concretely

| Dimension | Current state (free apps) | Our target |
|-----------|--------------------------|------------|
| Time to first tap on puzzle | 3–5 taps through menus | 1 tap from home screen (today's puzzle ready) |
| Keyboard | System keyboard shifts layout, covers grid | Custom overlay keyboard, grid always visible |
| Offline | Requires connection to load puzzle | Puzzles pre-fetched; fully playable offline |
| Progress | Lost on app restart in some apps | Auto-saved after every cell entry |
| Clue visibility | Clue buried in scrollable list | Active clue always visible in ClueBar above grid |
| Completion | Silent or generic toast | Celebratory animation + solve time displayed |
| Accessibility | Rarely considered | Screen reader support, high-contrast mode, zoom |
| Content | One source or zero | Local import + legally cleared free sources, extensible registry |

---

## Context

The goal is to build a modern, native-first crossword app for Android (Phase 1) with a clear path to iOS (Phase 2). The app should deliver a superior experience compared to existing offerings by combining the best patterns found across the open-source crossword/word-game ecosystem with modern mobile architecture.

This document synthesizes findings from six open-source repositories reviewed as reference material:
- **Crosshare** — full-stack web crossword platform (Next.js + Firebase)
- **Robocrosswords** — legacy Android offline solver (Java)
- **react-crossword** — React component library with SVG grid
- **Quackle** — C++ Scrabble engine with word validation/AI
- **Scrabble Solver** — TypeScript monorepo with trie-based word validation
- **Svelte Crossword** — Svelte component library with undo/redo and theming

---

## Repository Findings

### 1. Crosshare (`crosshare-org/crosshare`)

| Attribute | Detail |
|-----------|--------|
| **Stack** | TypeScript, React, Next.js, Firebase (Firestore + Cloud Functions), Redux, SCSS, Lingui i18n |
| **License** | AGPL-3.0 (limits commercial use) |
| **Puzzle Format** | `.puz` (AcrossLite binary) with custom JSON extensions for rebus, circles, metadata |
| **Grid Rendering** | React component hierarchy: `ViewableGrid` → `GridBase` utilities; CSS-driven cell styling |
| **State** | Redux with 3 reducers: `builderReducer` (32 KB, undo/redo history of 21 steps), `gridReducer`, `puzzleReducer` |
| **Backend** | Firebase Cloud Functions for scheduled ratings (Glicko), auto-moderation, email queue, analytics |
| **Validation** | `io-ts` runtime type validation on all Firestore reads |
| **Features** | Comments, ratings, contests, constructor pages, statistics, daily puzzles |

**Adopt:** `io-ts`-style runtime validation at data boundaries; Glicko rating system for puzzle difficulty; separation of builder vs. solver state; scheduled backend tasks for fresh daily content.

**Avoid:** Firebase vendor lock-in; AGPL license; 32 KB monolithic reducer — split by feature instead.

---

### 2. Robocrosswords (`adamantoise/robocrosswords`)

| Attribute | Detail |
|-----------|--------|
| **Stack** | Java (Android 2.3+, target API 26), Gradle, OkHttp3, TagSoup, SQLite |
| **Puzzle Formats** | `.puz`, `.jpz`, Newsday plaintext, Uclick XML |
| **Grid Rendering** | Custom canvas-drawing views: `CrosswordImageView`, `PlayboardRenderer`, `TouchImageView` |
| **State** | Activity-lifecycle state + SQLite via `PuzzleDatabaseHelper` |
| **Puzzle Sources** | 30+ source downloaders via Factory pattern: NYT, WSJ, WaPo, LA Times, USA Today, Universal, + 20 independents |
| **Architecture** | Monolithic Activities, Strategy pattern for movement, Adapter pattern for lists |

**Adopt:** Factory/registry pattern for puzzle source downloaders (extensible without code changes); offline-first design; broad `.puz`/`.jpz` format parsing; `MovementStrategy` abstraction for navigation.

**Avoid:** Legacy Java/Activity architecture; no modern lifecycle management; single-maintainer stagnation (last commit ~2018); manual OkHttp handling.

---

### 3. react-crossword (`JaredReisinger/react-crossword`)

| Attribute | Detail |
|-----------|--------|
| **Stack** | React 18, TypeScript, Styled-Components, Immer, Webpack 5 |
| **Puzzle Format** | Nested `{across, down}` objects → internal `CellData` 2D array; iPuz v2 import/export |
| **Grid Rendering** | **SVG-based** with dynamic `viewBox`; fixed 10-unit cell size; absolutely-positioned input overlay |
| **State** | `CrosswordProvider` context with Immer immutable updates; separate `masterGridData` (solution) vs `gridData` (progress) |
| **API** | Ref-based imperative API: `focus()`, `reset()`, `fillAllAnswers()`, `isCrosswordCorrect()`, `setGuess()` |
| **Keyboard** | Full arrow key, Tab/Space (direction toggle), Backspace, Home/End |
| **Storage** | `localStorage` with `"row_col"` coordinate keys |

**Adopt:** Resolution-independent rendering concept (we use Canvas, not SVG, but the principle of crisp rendering at any density applies); `master` vs. `player` grid data split; imperative programmatic control API; Immer-style immutable state; iPuz format support.

**Avoid:** SVG specifically — struggles at large grids on low-end devices; deep-clone on every state change (use structural sharing instead).

---

### 4. Quackle (`adamantoise/quackle`)

| Attribute | Detail |
|-----------|--------|
| **Stack** | C++ (80%), CMake, Qt5/Qt6, Common Lisp/Python/Perl utilities |
| **Architecture** | 3-layer: `libquackle` (pure game logic) → `libquackleio` (I/O) → Qt UI |
| **Word Validation** | Dictionary-based; validates primary word + all perpendicular words formed |
| **AI** | Pluggable player strategies; configurable difficulty levels |
| **Game Recording** | GCG format for replay and analysis |

**Adopt:** Strict separation of game-logic library from I/O from UI — essential for multiplatform; pluggable AI strategy pattern; game recording for replay/analysis features.

**Avoid:** Direct C++ dependency for a mobile app; Qt UI layer (replace with native mobile).

---

### 5. Scrabble Solver (`kamilmielnik/scrabble-solver`)

| Attribute | Detail |
|-----------|--------|
| **Stack** | TypeScript, Bun 1.3+, Next.js, React, Redux + Redux-Saga, SCSS, Cypress E2E |
| **Architecture** | Monorepo (Lerna): 9 packages — `configs`, `dictionaries`, `solver`, `types`, `logger`, main app |
| **Dictionary** | **Trie data structure** — sub-millisecond pattern matching on large word lists |
| **Solver Pipeline** | `generatePatterns` → `fillPattern` (trie) → `areDigraphsValid` → `getUniquePatterns` → score & rank |
| **Languages** | 8 language variants with locale-specific configs, word crawlers, icons, translations |
| **Offline** | Workbox service worker; dictionaries auto-downloaded to `~/.scrabble-solver` |

**Adopt:** Trie data structure for word validation and answer checking; monorepo package separation for shared types; multi-language architecture; offline dictionary caching.

**Avoid:** Full Redux-Saga complexity for simple puzzle state; monorepo overhead if staying single-platform initially.

---

### 6. Svelte Crossword (`russellsamora/svelte-crossword`)

| Attribute | Detail |
|-----------|--------|
| **Stack** | Svelte ^3, `svelte-keyboard` |
| **Puzzle Format** | Simple JSON: `{x, y, answer, direction, custom}` → normalized internal cell model |
| **Grid Rendering** | SVG-based `<g>` elements; responsive breakpoint at 720px |
| **State** | **Undo/redo history stack** (10 states, parallel `cellsHistory`/`cellsHistoryIndex` arrays) |
| **Themes** | classic, dark, citrus, amelia; CSS variable overrides prefixed `xd-` |
| **Animation** | Configurable `revealDuration` (default 1000ms); confetti on completion |
| **Components** | `Crossword` (orchestrator) → `Puzzle` (state engine) → `Cell`, `Clues`, `Toolbar`, `ClueBar`, `CompletedMessage` |

**Adopt:** Undo/redo history stack design; component hierarchy (orchestrator → state engine → leaf components); CSS-variable theming; celebration animation on completion; `ClueBar` showing active clue prominently on mobile.

---

## Crossword File Format Standards

### .puz (AcrossLite)
- Binary format, 52-byte header, CRC-16 checksums, ISO-8859-1 encoding
- Long-running legacy/interchange standard since 1996; many archives, indie constructors, and downloader tools still support it, but several major publishers now expose web players or proprietary APIs instead of direct `.puz` downloads
- Supports: rebus cells (limited to 4 chars in some implementations), circles, title/author/copyright
- No native Dart library exists; requires a pure Dart re-implementation or a port of [kotwords](https://github.com/jpd236/kotwords) (Kotlin) — binary parsing is straightforward given the documented spec
- Treat `.puz` as an import/export compatibility format, not the app's canonical storage model

### .ipuz (JSON, recommended primary format)
- Open JSON standard under Creative Commons; human-readable and machine-parseable
- Fields: `version`, `kind`, `dimensions`, `puzzle` (2D array), `solution`, `clues`
- Supports: unlimited rebus, multiple clue directions, formatted text, colors, background images, void cells
- **Recommended as the app's native storage format** with .puz import/export

### .jpz (XML)
- Used by PuzzleMe platform; supports variety crosswords, colored cells, non-standard layouts
- Less common than .puz/.ipuz but worth supporting for variety puzzles

---

## Puzzle Content Sources

| Source | Access | Notes |
|--------|--------|-------|
| **NYT** | Subscription required | Undocumented API at `nytimes.com/svc/crosswords/v6/`; GitHub archive (doshea/nyt_crosswords) |
| **The Guardian** | Free online | No official API; puzzles free to solve on site; archive back to 1999 |
| **LA Times / USA Today** | Free | Available via Wordplays.com aggregator |
| **Universal / Newsday** | Free | Direct downloader support (see Robocrosswords pattern) |
| **XWord Info** | Subscription | 27,931 crossword archive; agreement with NYT |
| **Open/indie constructors** | Varies | Many constructors distribute free .puz files |

### Source Integration Risk

> **See [topic-07](research/topic-07-legal-tos-puzzle-sources.md) for full legal/ToS analysis.** The table below reflects those findings. "Free to play" does not mean free to fetch, cache, or redistribute in a third-party app.

| Source | Stability | Legal/ToS finding | Cache policy | MVP decision |
|--------|-----------|-------------------|--------------|--------------|
| **Local `.puz` / `.ipuz` import** | High — user-controlled | User provides the file; app is not redistributing | Store body + progress locally | **Phase 1. Safest path.** |
| **Open/indie `.puz` feeds** | High when constructors publish static files | Safe only with constructor's explicit license + attribution | Follow license exactly | **Phase 1 if license is explicit.** |
| **Universal / Andrews McMeel** | Medium — endpoint can change | AMU ToS prohibits storing/copying content without written permission. Do not scrape. | Not applicable until permission granted | **Prohibited until AMU grants permission.** Contact AMU for syndication/API agreement. |
| **LA Times** | Medium/low — AmuseLabs token layer | LA Times ToS prohibits archiving, caching, scraping, copying, or distributing content without permission. | Not applicable until permission granted | **Prohibited until LA Times grants permission.** |
| **The Guardian** | Low — no official crossword API | Guardian ToS prohibits scraping/extracting content without written approval. Guardian Open Platform requires key and separate terms review. | Not applicable until permission granted | **Prohibited until Guardian grants permission or Open Platform API is confirmed for crosswords.** |
| **Wordplays / aggregators** | N/A | Aggregators cannot grant rights to underlying publisher puzzles. | Not applicable | **Prohibited.** |
| **NYT** | Low for third-party app access | Subscription required; `.puz` downloads discontinued 2021; user credentials needed; separate terms review required | Avoid caching premium content | **Post-MVP only, if ever.** |

**Strategy:** Phase 1 ships with local `.puz`/`.ipuz` import and any indie/constructor feeds with explicit written permission. Universal, LA Times, and Guardian require a business/legal decision before any downloader code is written. The plugin/registry architecture (Robocrosswords pattern) ensures new sources can be added later without core changes — but the `licenseStatus` guardrail must prevent any source with `needs_review` or `prohibited` status from being enabled at runtime (see source registry below).

---

## Recommended Architecture for the New App

### Platform Choice
**Flutter (Dart)** — strongly recommended over pure Kotlin Android for this project:
- Single codebase ships Android Phase 1, iOS Phase 2 with minimal rework
- Canvas-based rendering (similar to custom Android views in Robocrosswords) gives full control over grid drawing
- Material 3 / Cupertino theming adapts per platform automatically
- Strong ecosystem for crossword-style canvas UI, animations, accessibility
- Dart's `async/await` + Riverpod state management is well-suited to puzzle game state

Alternative: **Kotlin Multiplatform Mobile (KMM)** with Jetpack Compose — more native feel but significantly more boilerplate for shared UI.

### Layer Architecture (Clean Architecture)

```
┌────────────────────────────────────────────────┐
│                 Presentation Layer              │
│   Flutter Widgets: Grid, CluePanel, Toolbar     │
├────────────────────────────────────────────────┤
│              ViewModel / Riverpod               │
│  PuzzleNotifier, TimerNotifier, SettingsNotifier│
├────────────────────────────────────────────────┤
│                   Domain Layer                  │
│   PuzzleEngine, NavigationStrategy, Validator   │
├────────────────────────────────────────────────┤
│                   Data Layer                    │
│   SourceRegistry, PuzzleParser, Drift (SQLite)  │
└────────────────────────────────────────────────┘
```

**Key principles (learned from reference repos):**
- Game logic (PuzzleEngine) must be fully decoupled from UI (Quackle lesson)
- Separate `SolutionGrid` (immutable) from `PlayerGrid` (mutable progress) (react-crossword lesson)
- All external data validated at boundary (Crosshare/io-ts lesson)

### State Management: Riverpod + Freezed

```dart
// Entry mode — normal typing, pencil (tentative), or rebus (multi-character)
// Pencil may be deferred post-MVP; include in state to avoid a later breaking change
enum EntryMode { normal, pencil, rebus }

// Completion status — aligns with topic-11 stats/streak rules
// unsolved → inProgress → solved | solvedWithHelp | revealed
// solvedWithHelp is the combined "any assistance" bucket — covers both checked and hinted completions;
// the persisted completion_type column in Drift (topic-15) carries the finer distinction (clean/checked/hinted/revealed)
enum PuzzleStatus { unsolved, inProgress, solved, solvedWithHelp, revealed }

// Puzzle file formats — used in Puzzle.sourceFormat and PuzzleParser dispatch
enum PuzzleFormat { puz, ipuz, jpz }

// Source type — used in PuzzleSource.type
enum SourceType { free, subscription, local }

// Core puzzle state — all fields immutable; progress snapshots enable undo/redo
@freezed
class PuzzleState with _$PuzzleState {
  const factory PuzzleState({
    required Puzzle puzzle,                      // loaded puzzle (metadata + solution grid + clues)
    required Grid<CellProgress> playerGrid,      // user's current answers
    required FocusPosition focus,                // active cell (row, col)
    required Direction direction,                // across | down
    required EntryMode entryMode,                // normal | pencil | rebus
    required List<Grid<CellProgress>> history,   // undo stack (max 20 snapshots)
    required int historyIndex,                   // current position in undo stack
    required PuzzleStatus status,                // unsolved | inProgress | solved | solvedWithHelp | revealed
    required Duration elapsed,                   // timer; persisted as elapsed_ms in Drift
    @Default(0) int checkCount,                  // user-triggered check actions this session
    @Default(0) int revealCount,                 // user-triggered reveal actions this session
    @Default(0) int mistakeCount,                // distinct wrong guesses caught by check
    @Default(true) bool cleanSolveEligible,      // false after any reveal action
  }) = _PuzzleState;
}
```

### Grid Rendering: Custom Flutter Canvas Painter

```
CustomPainter (CrosswordGridPainter)
  ├── drawBlackCells()        — filled squares
  ├── drawCellNumbers()       — clue number labels (TextPainter)
  ├── drawUserLetters()       — user input (bold, centered)
  ├── drawFocusHighlight()    — active cell background
  ├── drawWordHighlight()     — all cells in active word
  ├── drawCrossHighlight()    — crossing word secondary highlight
  └── drawVerificationState() — correct (green) / incorrect (red) overlays
```

Benefits over SVG: hardware-accelerated, scales perfectly on high-DPI Android, no DOM overhead, supports smooth 60fps animations natively.

### Puzzle Data Model (internal)

```dart
// Immutable solution cell — part of the loaded puzzle, never changes
@freezed
class SolutionCell with _$SolutionCell {
  const factory SolutionCell({
    required int row,
    required int col,
    required bool isBlack,
    String? answer,             // null if black; rebus entries may be multi-char
    int? clueNumber,
    @Default(false) bool isCircled,
  }) = _SolutionCell;
}

// Mutable per-cell progress — driven by PuzzleState, persisted to Drift cell_progress
@freezed
class CellProgress with _$CellProgress {
  const factory CellProgress({
    required int row,
    required int col,
    String? guess,                             // null = empty; rebus uses full string
    @Default(CellState.empty) CellState state, // see CellState enum below
    @Default(false) bool wasChecked,           // true after any check action touched this cell
    @Default(false) bool wasRevealed,          // true after reveal filled or confirmed this cell
    @Default(false) bool isPencil,             // true when entered in pencil mode (tentative)
  }) = _CellProgress;
}
// CellState enum: empty | filled | checkedCorrect | checkedIncorrect | revealed
// — "checkedCorrect/Incorrect" only set by explicit user check action, never during normal entry
// — isPencil is separate from CellState so pencil cells are distinguishable after relaunch
//   (EntryMode.pencil is deferred post-MVP but the field is included to avoid a future schema migration)

// Immutable loaded puzzle — solution + metadata only
// sourceFormat lives here, not on PuzzleMetadata, to avoid duplication
@freezed
class Puzzle with _$Puzzle {
  const factory Puzzle({
    required String id,
    required PuzzleMetadata meta,
    required Grid<SolutionCell> grid,
    required List<Clue> acrossClues,
    required List<Clue> downClues,
    required PuzzleFormat sourceFormat,  // canonical format; meta.sourceId identifies the source
  }) = _Puzzle;
}

// Grid container — row-major flat list with width/height helpers
class Grid<T> {
  final List<T> cells;    // length == width * height
  final int width;
  final int height;

  const Grid({required this.cells, required this.width, required this.height});

  T cell(int row, int col) => cells[row * width + col];
  Iterable<T> get allCells => cells;
}

// Focused cell position — two-integer coordinate
@freezed
class FocusPosition with _$FocusPosition {
  const factory FocusPosition({
    required int row,
    required int col,
  }) = _FocusPosition;
}

// Clue domain model — aligns with clues table in topic-02
@freezed
class Clue with _$Clue {
  const factory Clue({
    required int number,
    required Direction direction,
    required String text,
    required int answerLength,   // matches clues.answer_length column
    required int startRow,
    required int startCol,
    required int sortOrder,
  }) = _Clue;
}

// Full metadata fields — all optional except title (may be empty string if absent)
// sourceId lives here (puzzle provenance); sourceFormat lives on Puzzle directly (not duplicated here)
@freezed
class PuzzleMetadata with _$PuzzleMetadata {
  const factory PuzzleMetadata({
    required String title,
    String? author,
    String? editor,
    String? publisher,
    String? copyright,
    String? notes,           // Theme explanation or special rules; display in solve screen overflow
    DateTime? publishDate,
    required String sourceId,   // e.g. 'local_import'; matches sources.id in Drift
  }) = _PuzzleMetadata;
}
```

### Puzzle Source Registry (extensible)

```dart
enum LicenseStatus { userImport, explicitPermission, openLicense, needsReview, prohibited }

abstract class PuzzleSource {
  String get id;
  String get displayName;
  SourceType get type;           // free | subscription | local
  LicenseStatus get licenseStatus;
  Future<List<PuzzleMeta>> fetchAvailable();
  Future<Puzzle> fetchPuzzle(String id);
}

class SourceRegistry {
  static final Map<String, PuzzleSource> _sources = {};

  static void register(PuzzleSource source) {
    assert(
      source.licenseStatus == LicenseStatus.userImport ||
      source.licenseStatus == LicenseStatus.explicitPermission ||
      source.licenseStatus == LicenseStatus.openLicense,
      'Source ${source.id} cannot be registered: licenseStatus is ${source.licenseStatus}',
    );
    _sources[source.id] = source;
  }

  static List<PuzzleSource> get all => _sources.values.toList();
}
```

New sources added by implementing `PuzzleSource` and calling `SourceRegistry.register()` — no core changes required. The `register` guard enforces the legal policy from [topic-07](research/topic-07-legal-tos-puzzle-sources.md): no source with `needsReview` or `prohibited` status can be enabled at runtime.

**`LicenseStatus` DB serialization:** Dart enum values are camelCase (`userImport`, `explicitPermission`, etc.) but the `sources.license_status` column in Drift uses snake_case strings (`user_import`, `explicit_permission`, `open_license`, `needs_review`, `prohibited`). Implement a Drift `TypeConverter<LicenseStatus, String>` in `sources_table.dart` that maps between the two representations.

### Navigation/Input Strategy

Detailed gameplay behavior for letter entry, deletion, checking, revealing, hints, completion labels, and stats effects is owned by [research topic #11](research/topic-11-game-mechanics-feedback.md). This section only defines the architectural shape.

Navigation uses a `MovementStrategy` (from Robocrosswords) so behavior can be swapped:
- **DefaultMovementStrategy**: advance to next unfilled cell in word, then jump to next word
- **SkipFilledStrategy**: skip already-filled cells when advancing
- Arrow keys, swipe gestures, tap-to-focus all delegate to the same strategy

### Undo/Redo

Parallel `history` list + `historyIndex` (Svelte-crossword pattern), max depth 20:
- Every cell change pushes a new `PlayerGrid` snapshot
- Undo/redo is O(1) index pointer movement
- Stored in memory only (not persisted — restart always resumes from last save)

---

## UI/UX Design Principles

### Mobile-First Grid Layout

```
Portrait:
┌──────────────────────────┐
│  ← Puzzle Title    ⏱ 4:23│  ← App bar (minimal)
├──────────────────────────┤
│  CLUE BAR (active clue)  │  ← Always visible, prominent
├──────────────────────────┤
│                          │
│   C R O S S W O R D      │
│     G R I D              │  ← Takes ~60% of screen
│       H E R E            │
│                          │
├──────────────────────────┤
│  [Clue list scrollable]  │  ← Collapsible, ~40% of screen
└──────────────────────────┘

Landscape: Grid left + Clue panel right (side-by-side)
```

### Touch Targets
- Minimum cell size: 44×44 dp (Apple HIG / Material minimum)
- Pinch-to-zoom: Allow up to 3× zoom for accessibility
- Double-tap cell: Toggle direction (across ↔ down)
- Tap clue in list: Jump grid focus to first unfilled cell of that clue

### Custom Keyboard
- Implement a custom alpha keyboard overlay (no system keyboard popup shifting layout)
- Include: Delete, Check (verify current word), Reveal (reveal current letter), directional arrows
- Keyboard style options: light / dark / auto (follows system)

### Theming
- Light and Dark modes (system-adaptive)
- Accent color customizable (at minimum: default blue, classic black/white, high-contrast)
- Define a `CrosswordTheme` extension on Flutter's `ThemeData`/`ColorScheme` to centralise all color tokens; widgets read from theme, never hardcode colors

### Animations

Gameplay-specific feedback rules are defined in [research topic #11](research/topic-11-game-mechanics-feedback.md); these are the visual primitives used by those rules.

- Cell fill: brief scale pulse on letter entry (~80ms)
- Word completion: subtle green flash across the completed word (~300ms)
- Puzzle completion: confetti or celebration overlay (user-dismissible)
- Reveal/check: cell "flip" animation revealing answer (~400ms)

### Accessibility
- Screen reader: `Semantics` widget wrapping each cell with label "Row X, Col Y, Clue N [across/down]: [clue text]"
- Keyboard navigation (when physical keyboard connected to Android)
- High-contrast theme option
- Text scaling: clue panel respects system text size; grid cell size stays fixed (users can zoom)

---

## Phased Roadmap

### Phase 1 — Android MVP
- [ ] Core puzzle engine (data model, navigation, validation)
- [ ] Custom canvas grid renderer
- [ ] OnboardingScreen (first-launch only): brief mechanics intro with no source-setup steps; router redirects here when `hasSeenOnboarding == false` (see [topic-13](research/topic-13-screen-inventory-routes.md) and [topic-16](research/topic-16-first-run-phase1.md))
- [ ] Import-first first-run experience: Home empty state points to local file import, not Browse Sources or Today's Puzzle (see [topic-16](research/topic-16-first-run-phase1.md))
- [ ] Local `.puz` and `.ipuz` import (user-provided files); add rights-cleared indie/constructor feeds only if explicit written permission exists — Universal, LA Times, and Guardian are all prohibited until publisher permission is obtained (see [topic-07](research/topic-07-legal-tos-puzzle-sources.md))
- [ ] Local puzzle storage + progress save/resume (Drift)
- [ ] Android Auto Backup configured for `crossword.db` (no backend needed for device-change continuity)
- [ ] Timer, undo/redo, check/reveal
- [ ] Light/dark theme
- [ ] Local crash reporting (Sentry or Firebase Crashlytics; no product analytics)

### Phase 2 — iOS + Polish
- [ ] iOS target via Flutter (minimal delta)
- [ ] App Store + Play Store listings
- [ ] Local notifications for continue/import reminders, streak reminders, and future licensed daily puzzle availability (no backend; `flutter_local_notifications`)
- [ ] Puzzle archive browser
- [ ] User statistics (streaks, average solve time, difficulty distribution)
- [ ] Network puzzle sources, if legal clearance obtained for Universal, LA Times, or Guardian by this point

### Phase 3 — Community & Content
- [ ] NYT integration (user-supplied credentials)
- [ ] Constructor upload (build your own puzzle)
- [ ] Comments and ratings
- [ ] Daily challenge / competitive mode

---

## Key Libraries (Flutter/Dart)

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `flutter_riverpod` | 3.x | State management | Recommended; Riverpod 3 current as of 2026 |
| `freezed` | current | Immutable data classes | Requires Flutter 3.10+; stable with build_runner |
| `build_runner` | 3.2+ | Code generation | Use `watch` mode; disable formatting of generated files |
| `go_router` | current | Navigation | Maintenance mode but still best-in-class for Flutter |
| `drift` | current | Local puzzle storage | **Replaces Hive/Isar** — SQLite-based, actively maintained by original author; Hive and Isar are now community-maintained after author abandonment |
| `dio` | current | Puzzle source downloaders | Production standard; interceptors, cancellation, progress |
| `xml` | 6.6+ | .jpz parsing | Actively maintained; supports XPath 3, SAX streaming |
| `html` | current | HTML parsing for Guardian downloader | Phase 2 only — add when Guardian source is legally cleared (see [topic-01](research/topic-01-puzzle-source-endpoints.md)); do not add for Phase 1 |
| `confetti` | current | Completion celebration | Active; two packages available (`confetti` or `flutter_confetti`) |
| `flutter_keyboard_visibility` | current | Keyboard state detection | Active but monitor for updates; unofficial fork exists as fallback |
| `dynamic_color` | current | Material You dynamic color on Android 12+ | Wraps `ColorScheme.fromSeed` with per-device wallpaper color; falls back gracefully on older Android |
| `flutter_local_notifications` | current | Post-MVP local reminders for continue/import prompts, streaks, and future licensed daily sources | Local only — no backend push tokens; defer user-facing reminders until Phase 2/post-MVP unless deliberately pulled into scope (see [topic-06](research/topic-06-push-notification-architecture.md)) |
| `share_plus` | current | Export Drift database file for manual backup/transfer | Used in Settings → Export data flow |
| `file_picker` | current | Import Drift database file from user-selected location | Used in Settings → Import data flow |
| `sentry_flutter` | current | Crash reporting | No product analytics in Phase 1; only crash/error events. Alternatively: `firebase_crashlytics` (see [topic-05](research/topic-05-analytics-crash-reporting.md)) |
| `crypto` | current | SHA-256 puzzle ID generation | Used in `PuzzleParser` to derive a stable `puzzleId` from file content; required before puzzle import ships (see [topic-14](research/topic-14-puzzle-parser-spec.md)) |
| `intl` | current | Date formatting and locale-aware date extraction | Used in streak calculations to extract `solved_date_local` as a `yyyy-MM-dd` calendar string from a local `DateTime` (see [topic-15](research/topic-15-streak-stats-algorithm.md)) |
| `shimmer` | current | Wave skeleton loading screens | Shown when puzzle or archive list loading exceeds 300 ms (see [topic-10](research/topic-10-design-ux-research.md)) |
| `flutter_animate` | current | Micro-interaction and animation DSL | Simpler API than raw `AnimationController`; drives cell pulse, word flash, and reveal animations (see [topic-10](research/topic-10-design-ux-research.md)) |
| `vibration` | current | Custom multi-pulse haptic pattern for puzzle completion | Requires `<uses-permission android:name="android.permission.VIBRATE"/>` in `AndroidManifest.xml` — add before first haptics run |
| `flutter_timezone` | current | Device timezone for zoned notification scheduling | Required alongside `timezone` for correct DST handling in `flutter_local_notifications` (see [topic-06](research/topic-06-push-notification-architecture.md)) — Phase 2 |
| `timezone` | current | Timezone database for zoned scheduling | Direct dependency of `flutter_local_notifications.zonedSchedule` — Phase 2 |
| `in_app_purchase` | current | Optional voluntary support IAP | Phase 2; required only if support tiers are added (see [topic-04](research/topic-04-monetization-model.md)) |
| `flutter_native_splash` | current | Generate native Android/iOS launch screens from a single config | **Dev dependency.** Run once to generate `launch_background.xml` and `LaunchScreen.storyboard`; not a runtime dependency. Configure with `#1565C0` background and centered app icon (see [topic-17 §18](research/topic-17-ux-missing-details.md)) |

### Android Platform Requirements
- `minSdkVersion`: 26 (Android 8.0) — acceptable for device coverage
- `targetSdkVersion`: **35+ required** for Google Play Store submission (as of August 2025)
- CustomPainter: Use `ChangeNotifier`/`Listenable` pattern for repaints; `Paint.enableDithering` is deprecated (now always true)
- Add `<uses-permission android:name="android.permission.VIBRATE"/>` to `AndroidManifest.xml` before using the `vibration` package for puzzle-completion haptics

---

## Settings Inventory

App settings are defined across multiple research topics. This table consolidates every setting that needs a key in `app_settings` (Drift) and a UI control in `SettingsScreen`. Implementers should treat this as the canonical settings list; the individual topic files contain the full rationale.

| Setting key | Type | Default | Defined in |
|-------------|------|---------|------------|
| `has_seen_onboarding` | bool | `false` | [topic-13](research/topic-13-screen-inventory-routes.md) |
| `theme_mode` | enum (`system`/`light`/`dark`) | `system` | [topic-10](research/topic-10-design-ux-research.md) |
| `colorblind_mode_enabled` | bool | `false` | [topic-10](research/topic-10-design-ux-research.md) |
| `haptics_enabled` | bool | `true` | [topic-11](research/topic-11-game-mechanics-feedback.md) |
| `sound_enabled` | bool | `false` | [topic-11](research/topic-11-game-mechanics-feedback.md) |
| `keyboard_layout` | enum or string | `default` | [topic-11](research/topic-11-game-mechanics-feedback.md) |
| `skip_filled_on_advance` | bool | `false` | [topic-11](research/topic-11-game-mechanics-feedback.md) |
| `daily_reminder_enabled` | bool | `false` | [topic-06](research/topic-06-push-notification-architecture.md) |
| `daily_reminder_time` | time string (`HH:mm`) | `"08:30"` | [topic-06](research/topic-06-push-notification-architecture.md) |
| `streak_reminder_enabled` | bool | `false` | [topic-06](research/topic-06-push-notification-architecture.md) |
| `streak_reminder_time` | time string (`HH:mm`) | `"20:00"` | [topic-06](research/topic-06-push-notification-architecture.md) |
| `notifications_sound_enabled` | bool | `false` | [topic-06](research/topic-06-push-notification-architecture.md) |
| `notifications_last_scheduled_at` | string (UTC ISO-8601) | `null` | [topic-06](research/topic-06-push-notification-architecture.md) — used by scheduler to detect stale reminders after reboot |
| `licensed_daily_reminder_enabled` | bool | `false` | Future-only; requires licensed daily source |
| `crash_reporting_enabled` | bool | `false` | [topic-05](research/topic-05-analytics-crash-reporting.md) |
| `streak_milestones_shown` | JSON list of ints | `[]` | [topic-15](research/topic-15-streak-stats-algorithm.md) |

Settings that are not user-configurable (e.g. `device_id`, sync state) live in the same `app_settings` table but should not appear in `SettingsScreen`.

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Puzzle copyright (NYT, etc.) | Require user credentials; never cache premium puzzles beyond solve session |
| Scraping prohibited sources | `SourceRegistry.register()` asserts `licenseStatus` is approved before any source can be enabled; `needsReview` and `prohibited` sources are blocked at runtime |
| Streak lost on phone upgrade | Enable Android Auto Backup in `AndroidManifest.xml`; include `crossword.db`, exclude WAL files — no backend needed (see [topic-09](research/topic-09-backend-sync-decision.md)) |
| Custom keyboard UX on Android | Test against GBoard/SwiftKey; provide fallback to system keyboard in settings |
| Grid performance on large puzzles (21×21+) | Canvas painter with `RepaintBoundary`; render only visible cells if scrolling |
| .puz binary format edge cases | Use battle-tested parser (kotwords port or pure Dart re-implementation) |
| iOS Phase 2 rework cost | Flutter eliminates this risk — same Dart code compiles to iOS |
| Google Play rejection | Set `targetSdkVersion 35` from day one; minSdkVersion 26 is fine |
| Local DB orphaned | Use Drift (SQLite, original author maintained) instead of Hive/Isar (both community-maintained after author abandonment) |
| Future sync schema migration | Add `deviceId`, `createdAt`, `updatedAt`, `isSynced`, `syncVersion` to `solve_sessions` and `updatedAt` to `cell_progress` from day one; define `NoOpSyncAdapter` stub (see [topic-09](research/topic-09-backend-sync-decision.md)) |

---

## Third-Party Library License Compatibility

The app's own license must be compatible with every third-party library it ships. Incompatible licenses can block publishing, commercial use, or support revenue — check each dependency before adding it.

### License Tiers and App Compatibility

| License | Permissive? | What it requires | Impact on app |
|---------|------------|------------------|---------------|
| **MIT / BSD / ISC** | Yes | Keep copyright notice | Compatible with any app license |
| **Apache 2.0** | Yes | Keep copyright notice + NOTICE file if provided | Compatible; also grants patent rights |
| **MPL 2.0** | Weak copyleft | Modifications to MPL files must be open-sourced; non-MPL files are not affected | Compatible if MPL-covered files are not modified |
| **LGPL 2.1 / 3.0** | Weak copyleft | Dynamic linking is usually fine; static linking triggers copyleft on your code | Requires careful review if statically linked (standard in Flutter) |
| **GPL 2.0 / 3.0** | Strong copyleft | Entire app must be GPL if it links GPL code | **Incompatible** with a proprietary app |
| **AGPL 3.0** | Strong copyleft (network) | Any app using AGPL code must release source under AGPL | **Incompatible** with a proprietary app — note Crosshare uses AGPL |
| **CC BY / CC BY-SA** | Varies | Attribution required; -SA triggers copyleft | Acceptable for assets (fonts, icons); not for code |
| **Proprietary / no license** | No | No rights granted | **Do not use** |

### Current Dependency Audit

| Library | License | Compatible? | Notes |
|---------|---------|-------------|-------|
| `flutter` / Dart SDK | BSD 3-Clause | Yes | |
| `flutter_riverpod` | MIT | Yes | |
| `freezed` / `freezed_annotation` | MIT | Yes | |
| `build_runner` | BSD | Yes | |
| `go_router` | BSD | Yes | |
| `drift` | MIT | Yes | |
| `dio` | MIT | Yes | |
| `xml` | MIT | Yes | |
| `archive` | BSD | Yes | |
| `confetti` | MIT | Yes | |
| `flutter_keyboard_visibility` | MIT | Yes | |
| `dynamic_color` | Apache 2.0 | Yes | |
| `flutter_local_notifications` | BSD | Yes | |
| `share_plus` | BSD | Yes | |
| `file_picker` | MIT | Yes | |
| `sentry_flutter` | MIT | Yes | |
| `firebase_crashlytics` | Apache 2.0 | Yes | |
| Roboto font | Apache 2.0 | Yes | Bundled font; include NOTICE |
| Roboto Mono font | Apache 2.0 | Yes | Bundled font; include NOTICE |

**Crosshare (AGPL-3.0):** We reviewed Crosshare for architecture ideas only. No Crosshare code is copied into this project. AGPL-3.0 does not restrict studying or referencing code — it only applies if Crosshare source is incorporated and distributed.

### Rules for Adding New Dependencies

1. Check `pub.dev` license badge before adding any package. Reject GPL, AGPL, and "no license" packages.
2. If a package is Apache 2.0, check whether it includes a `NOTICE` file — if so, that file must be included in the app's legal notices.
3. LGPL packages need case-by-case review because Flutter apps are statically linked. Use MIT/BSD/Apache alternatives when available.
4. Update this table when any new dependency is added.
5. Run `flutter pub deps` and check transitive dependency licenses — a permissive top-level package can pull in a GPL transitive dep.
6. Before shipping: generate a complete license list with `flutter pub run flutter_oss_licenses` or equivalent and include it in the app's About/Open Source Licenses screen (required by Play Store policy).

---

## Security

### Phase 1 Attack Surface

The Phase 1 app has a small security surface: no user accounts, no backend, no payment handling, no sensitive personal data. The primary security concern is **user-imported puzzle files** — a malformed or deliberately crafted `.puz` or `.ipuz` file is the only external input that can reach the parser.

### File Import Safety (Phase 1 Priority)

All imported files must be treated as untrusted input. The parser should never crash, hang, or corrupt state regardless of what a file contains.

| Rule | Implementation |
|------|---------------|
| Validate file size before parsing | Reject files over a reasonable cap (e.g. 5 MB); a standard crossword is under 50 KB |
| Validate file extension and MIME type | Reject files that don't match `.puz`, `.ipuz`, or `.jpz` before attempting to parse |
| Wrap all parse calls in `try/catch` | Catch all exceptions from binary parsing and JSON decoding; surface a user-friendly error, never a crash |
| Validate required fields after parsing | Confirm `width`, `height`, grid dimensions, and clue arrays are present and within sane bounds before constructing domain objects |
| Reject grids with nonsensical dimensions | E.g. width or height < 3, > 50, or grid cell count not equal to width × height |
| Clue text length cap | Truncate or reject clue text over a safe limit (e.g. 2000 chars) to prevent UI layout issues |
| No code execution from file content | Never `eval`, execute, or load Dart/native code from puzzle file content — this should be structurally impossible given the parsing approach, but confirm during review |
| Show a clear error on rejection | "This file could not be imported. It may be corrupted or in an unsupported format." — never expose internal error details to the user |

### Phase 2 / Future Concerns (Not Phase 1)

These are noted here so they are not forgotten when network sources are added:

- **HTTPS only:** Set `android:usesCleartextTraffic="false"` in `AndroidManifest.xml` and add a network security config before any downloader makes live requests.
- **No hardcoded credentials:** The Universal static URL token (see [topic-01](research/topic-01-puzzle-source-endpoints.md)) should come from remote config, not be hardcoded in source, so it can be rotated without an app release.
- **Dependency CVE scanning:** Add `flutter pub audit` or a GitHub Dependabot check to CI before Phase 2.
- **Backup content review:** Android Auto Backup sends `crossword.db` to the user's Google account. In Phase 1 this contains only puzzle progress — no credentials, no personal data. Re-review if any sensitive fields are added to the schema later.

---

## Verification Plan

**Core rendering and navigation**
1. Parse a known-good `.puz` fixture and render the grid correctly — no garbled characters, correct black squares
2. Tap a cell — correct cell highlights, word highlights, clue bar updates
3. Type a letter — fills cell and advances to next unfilled cell in word
4. Tap a clue in the list — focus jumps to first unfilled cell of that word
5. Double-tap a cell — toggles direction between across and down
6. Undo — last cell entry removed; redo — re-applied

**Check / reveal mechanics (see [topic-11](research/topic-11-game-mechanics-feedback.md))**
7. Check word — correct cells show `checkedCorrect` state (green), incorrect cells show `checkedIncorrect` state (red); empty cells unchanged
8. Replace a `checkedIncorrect` guess — cell clears back to `filled`, incorrect state removed
9. Reveal letter — cell fills with answer, marked `revealed`; re-tapping a letter on a revealed cell does nothing by default
10. Fill the entire grid with one wrong letter, do not check — puzzle does not auto-complete; player sees no forced error marking
11. Fill the entire grid correctly — completion overlay appears, timer stops, status is `solved`
12. Fill entirely correctly after using reveal — status is `solvedWithHelp`, labeled "Solved with hints", streak still counts by current lean
13. Reveal puzzle — confirmation prompt appears; confirming marks status `revealed`, does not count toward streak

**Persistence and recovery**
14. Kill app mid-solve and relaunch — puzzle state (guesses, check/reveal states, timer, focus) fully restored
15. Import a malformed `.puz` file — user sees friendly error message, app does not crash

**Accessibility and theme**
16. Toggle dark mode — all UI elements correctly themed with no hardcoded colors
17. Screen reader on: navigate to a cell, hear label with row/col/clue text; hear `checkedCorrect`, `marked incorrect`, or `revealed letter A` in cell value
