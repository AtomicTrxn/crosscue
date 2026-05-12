# Crosscue — Code Review & Improvement Plan

**Scope:** `crosscue/lib/**` (~13.8K hand-coded lines across 95 files) and supporting test/docs.
**Reviewer focus:** correctness, performance hotspots, design-pattern alignment with the project's stated architecture (see `ARCHITECTURE.md`, `CONVENTIONS.md`), and reduce-friction maintenance.
**Date:** 2026-05-11.

The codebase is in good shape overall — Clean Architecture is followed consistently, sealed Freezed unions and `Result<T,E>` are used correctly across layer boundaries, and the painter-based grid is a clear performance win. The findings below are mostly about reducing duplication, tightening allocations on hot paths, and trimming a few oversized files.

---

## Priority 1 — Fix soon (correctness / clear wins)

### 1.1 Duplicate `@override` annotation
**File:** `lib/features/import/data/parsers/puz_parser.dart:75-76`

```dart
@override
@override
Result<Puzzle, ParseError> parse(...)
```

Two consecutive `@override` annotations on the same method. The analyzer doesn't flag it today, but it's noise that survived a copy-paste. Delete one. (Likely there are no others — grepped, only this site.)

### 1.2 Hot-path `RegExp` instantiated per keystroke
**File:** `lib/features/solve/presentation/notifiers/solve_notifier.dart:196, 230`

```dart
if (!RegExp(r'^[A-Z]$').hasMatch(upper)) return false;
// ...
final upper = value.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
```

A new `RegExp` is compiled on every keypress and every rebus entry. These run inside the solve loop; while the cost is small, allocations on the input path are easy to remove. Lift them to `static final` (the parsers already do this — see `ipuz_parser.dart:41-42`):

```dart
static final _singleLetter = RegExp(r'^[A-Z]$');
static final _nonLetter = RegExp(r'[^A-Z]');
```

Same applies in `clue_panel.dart:409, 413` (`_referencedClueKeys`), and `crossword_grid.dart:217, 308`.

### 1.3 Status presentation logic duplicated across two screens
**Files:** `lib/features/home/presentation/screens/home_screen.dart:395-417` & `lib/features/archive/presentation/screens/archive_screen.dart:422-461`

`_statusColor` / `_statusIcon` (home) and `_iconAndColor` / `_statusNote` (archive) re-implement the same `ArchiveEntry` → (icon, color, label) mapping with slightly different APIs. Already mildly diverged. Extract to a single presentation helper, e.g.:

```dart
// lib/features/archive/presentation/widgets/archive_entry_status.dart
class ArchiveEntryStatus {
  final IconData icon;
  final Color color;
  final String? noteLabel;
  static ArchiveEntryStatus of(ArchiveEntry e, BuildContext ctx);
}
```

Reduces the chance of one screen showing a star while the other shows a checkmark for the same `isCleanSolve` state.

### 1.4 Side effects inside `AsyncValue.when` callbacks during build
**File:** `lib/features/solve/presentation/screens/solve_screen.dart:258-260`

```dart
data: (solveState) {
  _maybeShowCompletionSheet(solveState);
  _syncClueSelectors(solveState);
  // ... build widget tree
}
```

Both calls mutate state (`setState`, schedule modal sheet) directly inside a build pass. The existing guards (`_completionSheetShown`, `_selectorPuzzleId`) prevent loops, but the pattern violates the rule that `build` is a pure function of inputs and is a frequent source of "I can't reproduce it" bugs.

Switch to `ref.listen(solveProvider(widget.puzzleId), ...)` in `build()` for the completion side effect, and trigger selector sync from `solveNotifier`'s change events rather than from build. Same pattern issue in `app.dart:59-61` (`ref.watch(...).whenData(... init(...))`).

### 1.5 Solve screen is 940 lines, solve notifier is 776
**Files:** `lib/features/solve/presentation/screens/solve_screen.dart`, `lib/features/solve/presentation/notifiers/solve_notifier.dart`

`solve_screen.dart` mixes the screen widget, app bar, completion sheet, pause overlay, sharing, and lifecycle observer. The private sub-widgets (`_SolveAppBar`, `_CompletionSheet`, `_PauseOverlay`) are well-defined seams — extract each to `lib/features/solve/presentation/widgets/`. Cuts the screen file to roughly the parts that actually own state.

`solve_notifier.dart` has near-identical bodies for `checkCell` / `checkWord` / `checkGrid` and `revealCell` / `revealWord` / `revealGrid`. Extract pure functions into `lib/features/solve/domain/services/` (e.g., `GridMutator.checkRange`, `GridMutator.revealRange`) so the notifier only deals with state transitions.

---

## Priority 2 — Worth doing this iteration

### 2.1 Two parallel theming systems
**Files:** `lib/core/theme/{design_tokens,theme_colors,crossword_theme,app_theme}.dart`

`context.crosscueOnSurface3` (extension on `BuildContext`) coexists with `Theme.of(context).colorScheme.onSurfaceVariant`. Grep shows 12 files using `Theme.of(...).colorScheme` and 3 using `context.crosscue*`. The conventions doc names design tokens as the source of truth — pick one and migrate the holdouts. Mixed usage is the path to subtle dark-mode bugs.

### 2.2 Auto-dispose providers + manual invalidation = consider reactive streams
**Files:** `lib/features/home/presentation/providers/home_providers.dart`, `archive_providers.dart`

After every successful import or delete, `puzzleListProvider` and `archiveEntriesProvider` are manually invalidated from notifiers. That's correct but fragile — easy to forget on a new write path (we hit exactly this bug earlier in this session). Drift supports streaming queries; switch the DAOs to expose `Stream<List<...>>` and make the providers `StreamProvider`s. The UI then auto-refreshes on any mutation without callers needing to remember.

### 2.3 `_PuzzleRow` and `_ArchiveRow` are 90% the same widget
**Files:** `home_screen.dart`, `archive_screen.dart`

Both render: leading status icon, title, sub-line with size/date/author + pie progress, chevron, divider. Different by ~10 lines. Extract `lib/features/archive/presentation/widgets/puzzle_list_tile.dart` and parameterise the few differences (subtitle layout, delete callback). Pays back the rest of the lifetime of these screens.

### 2.4 `print` in production code path
**File:** `lib/features/import/presentation/notifiers/crosshare_notifier.dart:65`

```dart
// ignore: avoid_print
print('[CrosshareNotifier] unexpected error: $e\n$st');
```

The lint is suppressed but the call is wrong for production: `print` blocks the isolate, isn't routed through the existing `CrashReporter`, and ships to release builds. Replace with `debugPrint` (truncates, async-flushed) and report via `ref.read(crashReporterProvider).reportError(...)`.

### 2.5 Inline `TextStyle` allocations in build methods
**Files:** mostly `home_screen.dart`, `stats_screen.dart`, `archive_screen.dart`

Many widgets construct `TextStyle(fontSize: ..., fontWeight: ..., color: ...)` literals inside `build`. These allocate every frame the widget rebuilds. For styles that don't depend on `BuildContext`, hoist to `static const` at file scope. For styles that depend on theme, hoist into the design-token layer as `TextStyle Function(BuildContext)` helpers (or onto a `CrosscueTextStyles` extension). Net: fewer allocations + a single edit point per visual change.

### 2.6 Side-effect getter that hides `ref.read`
**File:** `lib/features/solve/presentation/screens/solve_screen.dart:75-91`

```dart
bool get _hapticsOn { final async = ref.read(hapticsEnabledProvider); ... }
```

Getters that read providers via `ref.read` (rather than `ref.watch`) silently miss subsequent state changes — a setting toggled while a puzzle is open will not take effect until next launch. Either watch in `build` and pass the resolved values down, or rename to `_currentHapticsOn()` so the snapshot semantics are explicit. Same for `_soundsOn`.

### 2.7 `clue_panel.dart` infinite-scroll math is unexplained
**File:** `lib/features/solve/presentation/widgets/clue_panel.dart:84-87, 283-313`

`_kVirtualLoopCount = 500` plus the wrap-around math in `_targetOffsetForClueIndex` is correct but opaque. Add a short comment block at the top of the file describing the contract (infinite virtual list that wraps every `count` items, anchored at `count * _kVirtualLoopCount` so the user can scroll in either direction without running out). Whoever owns this file next will thank you.

### 2.8 `WidgetsBindingObserver` registered via a Riverpod provider
**File:** `lib/core/providers/core_providers.dart:67-85`

```dart
@Riverpod(keepAlive: true)
void appLifecycleObserver(Ref ref) { ... }
```

Functional but unusual: an observer's lifetime is tied to provider disposal, and the provider has no return value. The comment notes "must be eagerly initialised in `CrosscueApp`". A regular `WidgetsBindingObserver` registered in `_CrosscueAppState.initState` is more discoverable — there's already one observer in `solve_screen.dart` doing exactly that pattern. Worth a refactor for consistency, or at minimum a clearer name like `appLifecycleHooksSentinel` so the no-value pattern signals intent.

### 2.9 Hard-coded route strings
**Search:** any inline `'/archive'`, `'/settings'`, etc. in non-routing code.

`CONVENTIONS.md` already mandates `Routes` constants. The recent back-navigation experiments demonstrated the failure mode (string typos silently miss redirects). Add an `analysis_options.yaml` custom_lint rule or a CI grep that fails on `context\.(go|push)\(['"]/.*['"]\)` outside `lib/core/routing/`.

---

## Priority 3 — Polish / lower impact

### 3.1 Large UI files that should be split *eventually*
- `stats_screen.dart` (721 lines, ~10 inline sub-widgets)
- `onboarding_screen.dart` (671 lines)
- `crossword_grid.dart` (620 lines)
- `archive_screen.dart` (514 lines, ~6 inline sub-widgets)
- `home_screen.dart` (521 lines)

These read fine today because each file is self-contained. Watch for the moment any of them sprouts a second file's worth of unrelated state — extract then.

### 3.2 `appVersionProvider` fallback string
**File:** `lib/core/providers/core_providers.dart:19-23`

Returns `'v—'` (literal em-dash) on platforms where `PackageInfo` fails. The em-dash is fine for display but trips up grep, log parsers, and tests. Prefer `'v?'` or `'vunknown'`.

### 3.3 Manual seed-vs-migration duplication
**File:** `lib/core/database/app_database.dart:113-175`

`_seedBuiltInSources` (full ORM, used on fresh install) and `_seedCrosshareSource` (raw SQL, used on v2→v3 migration) both insert the same row. The split exists for a real reason — migrations must tolerate partial historical schemas — but the relationship isn't obvious. Add a short README-style block to `_seedCrosshareSource` referencing the migration test and explaining why the raw SQL exists.

### 3.4 Test directory structure inconsistency
- `test/features/import/puz_parser_test.dart` — feature-root
- `test/features/import/data/repositories/import_repository_impl_test.dart` — mirrors lib

Pick one. Mirroring `lib/` makes new tests obvious to place; the flat-top exception for parsers is the kind of thing you forget about and re-divergence happens. Move the parser tests under `data/parsers/`.

### 3.5 `_AboutDialog._githubUrl` is hidden in a private widget
**File:** `lib/features/settings/presentation/screens/settings_screen.dart:177`

Will be needed again the moment you wire up "send feedback" or "report issue". Promote to `lib/core/constants/app_links.dart` (or `Routes` if you consider repo links route-adjacent).

### 3.6 `unawaited` everywhere on sound playback
**Files:** several in `solve_screen.dart`

`unawaited(ref.read(soundPlayerProvider).playFeedback())` discards errors. Fine for fire-and-forget audio, but if the audio backend is failing (codec issue, missing asset) you'll never know. Have `SoundPlayer.playFeedback` swallow + log internally so the call sites don't need to think about it.

### 3.7 Existing TODO list inside conversations / memory but not in code
The active todo state (T6 in-progress, T7–T11 pending) lives in session memory rather than `ISSUES.md` or GitHub issues. The CLAUDE.md already directs work via GitHub Issues — close the loop by either: (a) actually filing those items as GH issues so they survive sessions, or (b) merging the list into a `ROADMAP.md`. Currently they're only one context-loss away from being lost.

---

## Things the codebase gets right (don't change these)

- **Layer discipline.** Domain models never import Flutter (verified by spot-check); repositories are exposed as their interface type from providers; DAOs are the only Drift-aware code. This is rare in Flutter apps and pays for itself.
- **`Result<T,E>` at parser boundaries.** No `throw` across layer seams. `ImportRepositoryImpl.importBytes` discriminates `success` / `duplicate` / `failure` via a sealed union — the right shape for this domain.
- **Single `paint()` for the grid.** `CrosswordGridPainter` avoids a widget-per-cell rebuild storm. Big perf win that's invisible until you try the alternative.
- **Hidden offscreen `TextField` for soft-keyboard input.** Documented gotcha in `CONVENTIONS.md`. Survives Android's IME quirks.
- **`keepAlive: true` on infrastructure providers** with `ref.onDispose` cleanup (`SoundPlayer`, lifecycle observer). Lifecycle is explicit, not inferred.
- **Drift schema migrations with snapshot tests.** Version history is documented inline in `app_database.dart` and exercised in `app_database_test.dart`. Robust v1→v2→v3 coverage including data preservation. Excellent.
- **Crash handlers installed in `CrosscueApp.initState`.** Both `FlutterError.onError` and `PlatformDispatcher.instance.onError` covered.
- **Tests cover the things that bite:** parser fixtures, DAO behaviour, migration paths, source-policy logic, dispose-safety regressions.

---

## Suggested execution order

If picking one thing per sitting:

1. **1.1** — 30-second fix, cleans up a stray annotation.
2. **1.2** — 10-minute fix, removes per-keystroke allocations.
3. **2.4** — replace `print` with `debugPrint` + `CrashReporter`.
4. **1.3** — extract the shared status presenter (touches two screens).
5. **1.4** — move side effects out of `build` (highest correctness payoff).
6. **2.2** — switch to reactive Drift streams (eliminates a class of "tab didn't refresh" bugs permanently).
7. **1.5** — split `solve_screen.dart` and `solve_notifier.dart` (largest readability win).
8. **2.1** — finish the theme-tokens migration.
9. Remainder, opportunistically.
