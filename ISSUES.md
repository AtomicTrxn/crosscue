# Issues & Enhancements — Crosscue

Bugs and enhancement requests that fall outside the current sprint scope.
Agents should read this file before starting any sprint to check for items
that should be pulled into the current or upcoming sprint.

Status key: 🐛 Bug · ✨ Enhancement · 💡 Idea · ✅ Done · ❌ Won't Fix

---

## Open

| # | Type | Title | Sprint Target | Notes |
|---|------|-------|---------------|-------|
| 3 | ✨ | In-app puzzle downloader for free/licensed sources | Sprint 8+ | See detail below; legal review required before any source ships |

## Done

| # | Type | Title | Shipped | Notes |
|---|------|-------|---------|-------|
| 5 | ✨ | Solve screen: replace ClueBar header with inline word highlight only | 2026-05-06 | Removed `ClueBar`; same-cell tap still toggles direction |
| 6 | ✨ | Keyboard: larger keys for finger-friendly tapping | 2026-05-06 | Letter keys are 44dp/14px; mini puzzles use 48dp/15px; special keys are 46dp |
| 8 | 🐛 | Settings → How to Play does not launch onboarding | 2026-05-06 | Added replay route query to bypass the onboarded-user redirect |
| 11 | ✨ | Clear data modal: cancel button larger and blue | 2026-05-06 | Cancel is now a filled primary-blue button |
| 15 | ✨ | Reveal puzzle dialog: cancel button blue | 2026-05-06 | Cancel is now a filled primary-blue button |
| 16 | 🐛 | Revealing entire puzzle does not mark puzzle as complete | 2026-05-06 | Verified reveal completion path and tightened terminal-state UI handling |
| 17 | ✨ | Clue panel: auto-center active clue and tappable rows | 2026-05-06 | Rows are tappable and focus the first empty cell in the selected clue |
| 18 | ✨ | Clue panel: larger font, show only 5 clues | 2026-05-06 | Clue text is 14px and panel height is capped to five visible rows |
| 7 | ✨ | Completed words/letters: soft green fill color | 2026-05-06 | Fully correct words now use muted green fill/text when not focused/highlighted |
| 9 | ✨ | About screen: icon, description, GitHub link | 2026-05-06 | Replaced stub with an About bottom sheet and copyable GitHub URL |
| 12 | 🐛 | Crash reporting saves nothing — wire up local log | 2026-05-06 | Added local rolling crash log at app documents `crash_log.txt`; no transmission |
| 13 | 🐛 | Colorblind mode (Deuteranopia) not implemented | 2026-05-06 | Added enum-backed setting and navy dot indicator for correct letters |
| 19 | ✨ | Clue pane: sticky headings, 3-row wraparound viewport | 2026-05-06 | Across/Down headings are fixed; each column shows previous/selected/next with wraparound |
| 20 | ✨ | Keyboard: increase key size again | 2026-05-06 | Keys are taller/larger with responsive widths for narrow screens |
| 10 | 🐛 | Export and import data not implemented or wired up | 2026-05-06 | Added JSON stats export/share and additive import into backup-only stats rows |
| 14 | 🐛 | Sounds not implemented; merge with haptics into "Touch & Sound" section | 2026-05-06 | Added `audioplayers` beep generation and wired sounds to key/check/completion events |
| 24 | ✨ | Puzzle reset dialog: cancel button blue | 2026-05-06 | Reset remains red; Cancel is now a filled primary-blue button |
| 26 | ✨ | Stats page: add "Streak" section title above current/longest | 2026-05-06 | Added uppercase `STREAK` label above current/longest streak cells |
| 29 | ✨ | Archive page: remove floating add (+) button | 2026-05-06 | Removed the redundant Archive add/import shortcut |
| 31 | 🐛 | Cross-direction column highlight too prominent | 2026-05-06 | Removed the perpendicular word background highlight; active word and focus remain |
| 21 | ✨ | Sources: row-tap opens centered modal, condense wording, remove trailing button | 2026-05-06 | Local Import routes directly to import; non-local source rows open compact centered dialogs with no trailing button |
| 28 | ✨ | About: use centered dialog, match app icon exactly | 2026-05-06 | Replaced About bottom sheet with centered dialog using the launcher icon asset |
| 30 | ✨ | Today page add button: context-aware routing + blue color | 2026-05-06 | Add button now uses primary blue and routes to local import until a downloader-capable source exists |
| 32 | ✨ | "Crosscue" home header: centered, overlay banner, cold-start only | 2026-05-06 | Added a once-per-process slide-in overlay banner without AppBar layout shift |
| 34 | ✨ | Today page: pie chart completion indicator next to puzzle size | 2026-05-06 | Added 18dp inline completion pies using latest session progress fraction |
| 22 | ✨ | Replace "Future Downloads" with "Community Crosswords" + Crosshare source | 2026-05-06 | Replaced placeholder section with Crosshare candidate; downloads stay blocked pending content-rights review |
| 23 | ✨ | Clue panel: scrollable numbered list, full-width dynamic keyboard, haptic scroll | 2026-05-06 | Clue lists now scroll independently in number order, fill available height, haptic on scroll, and commit selection on release |
| 25 | ✨ | App icon: larger logo with thin margin inside circle | 2026-05-06 | Regenerated Android launcher icons with a larger crossword mark |
| 27 | 🐛 | Onboarding end: navigate to import screen, not today | 2026-05-06 | Final onboarding CTA now uses `context.go(Routes.import_)` |
| 33 | ✨ | Android lifecycle: audit all app states | 2026-05-06 | Detached state now flushes pending saves; lifecycle QA checklist added to deployment docs |

---

## Detail

### #21 — Sources: row-tap opens centered modal, condense wording

**Type:** Enhancement
**Reported:** 2026-05-06

Wrap each source `ListTile` in a `GestureDetector` / `InkWell` (remove the trailing `IconButton`). On tap, show a centered `AlertDialog` (not `showModalBottomSheet`) containing the source name, license status, and a brief one-line description. Keep all text under ~120 chars to avoid scrolling on a 360dp-wide dialog. The dialog's positive action is "Enable" / "Disable" and negative is "Cancel".

**Key file:** `source_management_screen.dart`

---

### #22 — Replace "Future Downloads" with "Community Crosswords" + Crosshare

**Type:** Enhancement
**Reported:** 2026-05-06

Remove the "Future Downloads" placeholder section from the Settings → Sources screen. Replace with a "Community Crosswords" section containing a single pre-registered source:

- **Crosshare** — `https://crosshare.org` — `LicenseStatus.openLicense`
  - API: `https://crosshare.org/api/dailymini` returns a public daily mini puzzle in a documented JSON format
  - Register in `SourceRegistry` as `CrosshareSource` implementing `PuzzleSource`
  - Display name: "Crosshare Daily Mini"
  - Attribution required: true (link to crosshare.org in puzzle detail)
  - GitHub reference: `https://github.com/crosshare-org/crosshare`

Wire the downloader into the existing import pipeline once the source is registered. The actual HTTP fetch lives in a new `CrosshareSource` data class under `features/import/data/sources/`.

**Key files:** `source_registry.dart`, `features/import/data/sources/crosshare_source.dart` (new), `source_management_screen.dart`

---

### #23 — Clue panel: scrollable numbered list, dynamic keyboard, haptic scroll

**Type:** Enhancement
**Reported:** 2026-05-06

Three tightly coupled changes:

1. **Scrollable clue lists in number order** — Both the Across and Down columns scroll independently. Clues are sorted by number ascending (already the case in `Puzzle.clues`). Use a `ListView` with a `ScrollController` per column.

2. **Dynamic keyboard width** — `CrosswordKeyboard` should use `LayoutBuilder` so letter keys fill the full available width with no fixed `maxWidth` cap. Keys grow as wide as the screen allows while maintaining proportional spacing.

3. **Panel extends to keyboard top** — Remove any fixed height on the clue panel. It should be `Expanded` and fill all space between the grid bottom and the keyboard top.

4. **Haptic feedback on scroll** — As the user drags the clue list, fire `HapticFeedback.selectionClick()` each time the highlighted item changes (one tick per clue boundary crossed). Gate on the haptics setting.

5. **Cross-side deferred update** — While the user is actively scrolling the Across list, the Down list does not follow until the user lifts their finger and a clue is committed. Then the Down `ScrollController` animates to the matching cross-clue. This prevents jitter. Implement via the `ScrollController.addListener` + a debounce on `onScrollEnd` (`NotificationListener<ScrollEndNotification>`).

**Key files:** `clue_panel.dart`, `crossword_keyboard.dart`, `solve_screen.dart`

---

### #30 — Today page add button: context-aware routing + blue color

**Type:** Enhancement
**Reported:** 2026-05-06

The floating action button (or equivalent) on the Today/Home screen should:
- Check `SourceRegistry.enabledSources` — if any source has a downloader (Phase 2), route to the community downloader screen; otherwise route to `Routes.import_` (local file pick)
- Color: `#1565C0` (the same blue used for the selected bottom-nav tab indicator)
- For now (no downloader implemented), always route to `Routes.import_`; the condition is wired but the downloader branch is a no-op stub

**Key file:** `home_screen.dart`, `app_router.dart` (if a new route is needed)

---

### #31 — Cross-direction column highlight too prominent

**Type:** Bug / UX
**Reported:** 2026-05-06

When a cell is focused, `CrosswordGridPainter` paints the perpendicular word's cells in a light-blue wash (`#E3F2FD`). At normal cell sizes this makes the letter glyphs hard to read against the tinted background.

**Fix options (pick one):**
- **Remove the cross highlight entirely** — the active word (blue) and focused cell (gold) give enough orientation
- **Thin border only** — paint a 1dp `#BBDEFB` border on cross-word cells instead of flooding the cell background

Preferred: remove entirely. If user testing shows loss of orientation, fall back to thin border. Update `CrosswordGridPainter._paintCellBackground`.

**Key file:** `crossword_grid_painter.dart`

---

### #32 — "Crosscue" home header: centered overlay banner, cold-start only

**Type:** Enhancement
**Reported:** 2026-05-06

The "Crosscue" title currently renders as a standard `AppBar` title, causing layout shift when it appears/disappears. Replace with:

- A `Stack` overlay at the top of `HomeScreen` — the banner sits above the content, not inside the layout flow
- The banner slides down from off-screen on cold start, displays for ~2 seconds, then slides back up with a `SlideTransition`
- After dismissal it is removed from the tree (`setState(() => _bannerVisible = false)`) so it takes no space
- "Cold start only" = show once per process lifetime. Use a static `bool _hasShown = false` in `HomeScreen` state or a `ref.read` of a simple `keepAlive` boolean provider — no persistence needed (next app launch is a new process)
- Text: centered, `24px w700`, navy `#0A2A6E`

**Key file:** `home_screen.dart`

---

### #33 — Android lifecycle: audit all app states

**Type:** Enhancement / Audit
**Reported:** 2026-05-06

Verify the app responds correctly to every Android lifecycle transition:

| State | Android event | Expected app behaviour |
|-------|--------------|----------------------|
| **Foreground → Background** | `AppLifecycleState.paused` | Pause solve timer; autosave progress |
| **Background → Foreground** | `AppLifecycleState.resumed` | Resume timer only if puzzle was running (not paused by user); refresh home puzzle list if stale |
| **Background → System kill** | Process death | Progress already autosaved; no action needed at kill time |
| **Hidden (pip / split)** | `AppLifecycleState.hidden` | Same as paused — already handled; verify |
| **Inactive (phone call overlay)** | `AppLifecycleState.inactive` | Do nothing (brief interruption; timer keeps running) |
| **Detached** | `AppLifecycleState.detached` | Flush any pending DB writes |

Check `SolveScreen.didChangeAppLifecycleState` — currently handles `paused` and `hidden`. Confirm `detached` triggers a final `saveProgress` call. Confirm `resumed` does not restart a user-paused puzzle. Add widget test or manual QA checklist to DEPLOYMENT.md.

**Key files:** `solve_screen.dart`, `solve_notifier.dart`, `DEPLOYMENT.md`

---

### #34 — Today page: pie chart completion indicator next to puzzle size

**Type:** Enhancement
**Reported:** 2026-05-06

Inline a small circular progress indicator after the size label in the featured puzzle card and list rows on the Today/Home screen:

- Size: `18dp` diameter
- Proportion: `filledCells / totalWhiteCells` from the puzzle's latest session (0.0 if not started)
- Colors: filled arc = `#1565C0` navy, track = `#E0E0E0` grey
- Not started: empty circle (track only)
- Complete: solid navy circle
- Use a `CustomPainter` arc or Flutter's `CircularProgressIndicator` with `strokeWidth: 2.5` and `backgroundColor`
- Positioned inline: `"15×15  [pie]"` with `4dp` gap between text and chart

The `ArchiveRepositoryImpl.getArchiveEntries()` already loads session data alongside metadata — use `latestSession` to derive fill fraction without a new query.

**Key files:** `home_screen.dart`, optionally a new `_PieProgress` widget in `home/presentation/widgets/`

---

### #2 — Long-press grid cell → contextual Check/Reveal menu

**Type:** Enhancement  
**Reported:** 2026-05-04  
**Target:** Sprint 6 (can pull into earlier sprint if time allows)

**Description:**  
Long-pressing any white (non-black) cell in the crossword grid should show a
contextual popup menu anchored near the tapped cell. This gives quick access
to check/reveal actions without reaching up to the `⋮` AppBar menu.

**Menu items:**
- Check letter
- Check word
- ─── (divider)
- Reveal letter
- Reveal word

> Reveal puzzle is intentionally omitted from this menu — it is a
> high-impact action that belongs in the AppBar menu with its confirmation
> dialog (topic-11).

**Implementation notes:**
- Detect long-press in `CrosswordGrid` via `GestureDetector.onLongPressStart`
  (use `onLongPressStart` to get the local position for menu anchoring).
- Convert the long-press position to `(row, col)` using the same hit-test math
  as `onTapDown`.
- Move focus to the long-pressed cell first, then show the menu so the menu
  always acts on the correct cell.
- Use `showMenu<_CheckRevealOption>()` with a `RelativeRect` derived from the
  tap position to anchor the menu near the cell.
- Call the same `SolveNotifier` methods (`checkCell`, `checkWord`, etc.) that
  the AppBar menu already uses.
- Key file: `crossword_grid.dart` — add long-press handler alongside the
  existing `onTapDown` handler.

---

### #5 — Solve screen: replace ClueBar header with inline word highlight only

**Type:** Enhancement
**Reported:** 2026-05-06

**Description:**
The current solve layout has a `ClueBar` widget above the grid that shows the active clue number + text ("27A Main components in Velcro"). Remove this bar entirely. The active word highlight in the grid itself (blue row/column) is the primary visual cue. The clue text still appears in the clue panel below the grid.

Repeated taps on the **same already-focused cell** should toggle direction (across ↔ down). This behavior already exists in `SolveNotifier.tapCell()` — verify it is working correctly once the ClueBar is removed.

**Implementation:**
- Remove `ClueBar` widget call from `SolveScreen` layout
- Remove `ClueBar` import
- The freed vertical space goes to the clue panel (Expanded flex) and/or keyboard
- Keep `SolveNotifier.tapCell()` toggle-direction logic as-is — it already toggles on same-cell tap

**Key files:** `solve_screen.dart`, `clue_bar.dart` (can be deleted once removed)

---

### #6 — Keyboard: larger keys for finger-friendly tapping

**Type:** Enhancement
**Reported:** 2026-05-06

**Description:**
Current spec: `height: 36dp`, `fontSize: 12px`. Keys feel small on a physical device. Increase to `height: 44dp`, `fontSize: 14px` for letter keys; `height: 44dp`, `width: 46dp` for `⌫` and `✓` special keys. For small puzzles (≤ 7×7), use `height: 48dp`, `fontSize: 15px` (already spec'd in §03).

**Key file:** `crossword_keyboard.dart`

---

### #9 — About screen: icon, description, GitHub link

**Type:** Enhancement
**Reported:** 2026-05-06

**Description:**
The current About section in Settings is a stub row. Replace with a proper screen or expanded tile containing:
- App icon (from assets or `Image.asset`)
- App name "Crosscue" in `20px w600`
- Tagline: "A clean, offline-first crossword app for Android" in `14px #666`
- Version string from `package_info_plus` (add package if not present)
- Tappable GitHub URL: `https://github.com/AtomicTrxn/crossque` using `url_launcher`

**Key file:** `settings_screen.dart` — expand the About list tile or push a new `AboutScreen`

---

### #12 — Crash reporting: save to local file (Phase 1)

**Type:** Bug / Enhancement
**Reported:** 2026-05-06

**Description:**
`NoOpCrashReporter` in `core/telemetry/crash_reporter.dart` silently discards all errors. For Phase 1, implement a `LocalCrashReporter` that:
- Appends crash details (timestamp, error message, stack trace) to a rolling log file at `<documents>/crash_log.txt`
- Caps the file at 500 KB (trim oldest lines on overflow)
- Exposes a `Future<String?> readLog()` method for future diagnostic export

Wire it up in `core_providers.dart` replacing `NoOpCrashReporter`. No transmission yet — that is Phase 2 (Sentry / Firebase Crashlytics).

**Key files:** `core/telemetry/crash_reporter.dart`, `core/providers/core_providers.dart`

---

### #16 — Revealing entire puzzle does not mark as complete

**Type:** Bug
**Reported:** 2026-05-06

**Description:**
`SolveNotifier.revealGrid()` fills every cell with the solution letter and sets each cell's state to `CellState.revealed`, but does not call `_checkCompletion()` (or equivalent) afterward. The puzzle stays in `inProgress` status indefinitely and the completion sheet never appears.

**Fix:** After filling all cells in `revealGrid()`, explicitly set:
```dart
status = PuzzleStatus.revealed
```
and call `_markComplete(CompletionType.revealed)` so the session is persisted and the completion sheet is triggered.

**Key file:** `solve_notifier.dart` — `revealGrid()` method

---

### #10 — Export / Import session stats

**Type:** Bug / Enhancement
**Reported:** 2026-05-06
**Decisions:** 2026-05-06

**Scope:** Completed `solve_sessions` rows only — not puzzle files, not cell progress, not incomplete sessions.

**Format:** JSON array of session objects:
```json
[
  {
    "completionType": "clean",
    "elapsedMs": 312000,
    "solvedDateLocal": "2026-05-06",
    "solvedTimezone": "CST",
    "width": 15,
    "height": 15,
    "puzzleTitle": "Themeless Monday #875"
  }
]
```

**Export:** Query all rows in `solve_sessions` where `status = 'completed'` or `'revealed'`, serialize to JSON, share via Android share sheet (`share_plus`, already in stack).

**Import:** Parse JSON, for each record insert into `solve_sessions` if no existing row matches `(puzzleTitle + solvedDateLocal)` — additive, never replaces. After import, invalidate `statsDataProvider` so the stats screen recomputes. No changes needed to `StatsRepositoryImpl` — it runs over the larger dataset automatically.

**Rationale for detail over summary:** `StatsRepositoryImpl` computes every stat (streak, personal best, completion rate) from raw session rows. Exporting summary numbers would force a second codepath in stats; streak calculation requires per-day `solvedDateLocal` dates that can't be reconstructed from aggregated values.

**Key files:** `settings_screen.dart` (wire up the stubs), new `StatsExportService` in `features/stats/data/`, `stats_dao.dart` (add `getAllCompletedSessions()` query)

---

### #13 — Colorblind mode: Deuteranopia dot indicator

**Type:** Bug / Enhancement
**Reported:** 2026-05-06
**Decisions:** 2026-05-06

**Visual:** When colorblind mode is enabled, draw a small filled circle (dot) in the upper-right corner of any cell whose `CellState == checkedCorrect` or whose letter matches the solution. Dot color: `#1565C0` (navy — safely distinguishable for deuteranopes). No palette swaps needed.

**Extensibility:** Define a `ColorblindMode` enum in `enums.dart`:
```dart
enum ColorblindMode { none, deuteranopia }
// Future values: protanopia, tritanopia, highContrast
```
Store the selected value in `AppSettingsRepository` (replace the current `bool` with the enum string). `CrosswordGridPainter` reads the mode and dispatches to a `_paintAccessibilityOverlay(canvas, cell, rect, mode)` method — adding a new type is one new case in that switch.

**Settings screen note** (below the toggle/picker):
> "When enabled, a dot appears in the corner of correct letters."

**Key files:** `crossword_grid_painter.dart` (dot rendering), `enums.dart` (new enum), `app_settings_repository.dart` / `app_settings_repository_impl.dart` (store enum), `settings_screen.dart` (add explanatory subtitle), `settings_providers.dart` (update notifier type)

---

### #14 — Sounds: programmatic beeps via audioplayers; merge with haptics

**Type:** Bug / Enhancement
**Reported:** 2026-05-06
**Decisions:** 2026-05-06

**Package:** `audioplayers` — add to `pubspec.yaml`.

**Sound generation:** Generate soft sine-wave beep at app startup, cache as `Uint8List`, play via `AudioPlayer.play(BytesSource(...))`. Parameters:
- Frequency: 440 Hz (A4) — warm, not sharp
- Duration: 80ms
- Envelope: 5ms attack, 60ms sustain, 15ms release
- Amplitude: 0.4 (gentle, not jarring at max volume)

One sound variant is enough for all events. Volume/pitch variation (e.g. higher note on word complete) is a future enhancement.

**Trigger points** — mirror haptic trigger points exactly:
| Event | Haptic | Sound |
|-------|--------|-------|
| Key tap | `lightImpact` | soft beep |
| Word complete | `mediumImpact` | soft beep |
| Puzzle complete | `vibrate` (pulse) | soft beep |
| Check correct | *(none)* | soft beep |
| Check incorrect | `vibrate` | *(no sound — haptic only)* |

**Settings section rename:** Rename the current "Sounds" / "Haptics" area in `settings_screen.dart` to **"Touch & Sound"**. Group haptics toggle and sounds toggle together under that header. The name avoids confusion with "Send Feedback" type affordances.

**Key files:** `pubspec.yaml` (add `audioplayers`), new `core/audio/sound_player.dart`, `settings_screen.dart` (rename section, group toggles), `solve_screen.dart` / `crossword_keyboard.dart` (wire sound calls alongside haptic calls)

---

### #17 & #18 — Clue panel: tappable rows, auto-center, larger font, 5-clue limit

**Type:** Enhancement
**Reported:** 2026-05-06

**Description:**
Three related improvements to the clue panel below the grid:

1. **Tappable clue rows** — Tapping any visible clue row in the panel should call `SolveNotifier.tapCell(clue.startRow, clue.startCol)` (or the first empty cell in that word) and set direction to match the clue. This lets users navigate by clue rather than by cell.

2. **Auto-center active clue** — When the focused word changes, animate the across and down `ScrollController` so the highlighted clue row is vertically centered in its half of the panel. Use `ScrollController.animateTo` with `150ms easeOut` (already spec'd in design/README.md §02).

3. **Font size and row limit** — Increase clue text from current size to `14px`. Show at most 5 visible rows per column (across / down) so the panel has a fixed height. Combined with removing the `ClueBar` (#5) and larger keyboard keys (#6), this keeps the full layout within the screen without scrolling.

**Key file:** `clue_panel.dart`

---

### #3 — In-app puzzle downloader for free/licensed sources

**Type:** Enhancement  
**Reported:** 2026-05-04  
**Target:** Sprint 8+ (depends on `SourceRegistry` from Sprint 8; legal review required per source)

**Description:**  
Add an in-app downloader so users can fetch today's puzzle directly without
manually finding and importing a file. Only sources with `LicenseStatus` of
`openLicense` or `explicitPermission` may be enabled (topic-07 hard rule).

**Prep shipped 2026-05-06:**  
`PuzzleSource` now carries license URL, permission contact, cache policy,
raw-payload retention, commercial-use, last-review, and review-note metadata.
Settings → Puzzle sources exposes those fields and includes a source review
checklist. A reusable review template lives at
`docs/source-legal-review-template.md`. This issue remains open because no
online source has been rights-cleared for downloader implementation.

**Update 2026-05-06:**  
Crosshare is visible as a Community Crosswords candidate, but downloader
implementation is still blocked here. Crosshare's app code is AGPL-3.0; hosted
puzzle-content rights, API terms, attribution, and cache policy still need
human review before Crosscue may fetch or cache puzzle bodies.

> ⚠️ **Legal guardrail:** Read [topic-07](research/topic-07-legal-tos-puzzle-sources.md)
> in full before writing any downloader code. Universal, LA Times, and The Guardian
> are currently classified `needsReview` — they **must not** be enabled until
> written permission or an official API agreement is in place.

**Candidate sources and API status:**

| Source | API / Feed | Status | Notes |
|--------|-----------|--------|-------|
| **Universal Crossword** | Public JSON endpoint (no auth, static token in URL) | `needsReview` | Best candidate — clean REST API, no scraping. See topic-01 for URL pattern. Contact Andrews McMeel for permission. |
| **LA Times** | AmuseLabs platform — has an official paid API (`client_id`/`client_secret` via `support@amuselabs.com`) | `needsReview` | Unofficial token extraction is fragile (breaks on AmuseLabs changes). Use official API path if licensed. |
| **The Guardian** | No public API for crosswords. Data embedded in HTML (`<gu-island>` element). Guardian Open Platform API exists but crossword coverage needs direct verification. | `needsReview` | Requires HTML parsing (`html` package). Guardian Open Platform API key needed for any official path. |
| **NYT** | No public API; subscription required | `prohibited` | Do not implement. |
| **Indie / constructor feeds** | `.puz` / `.ipuz` direct download URLs published by constructors | `openLicense` (per feed) | Safest path for Phase 1 — many constructors publish free daily feeds. Needs a feed registry. |

**Recommended implementation order:**
1. Finish Sprint 8 `SourceRegistry` + `LicenseStatus` enforcement first — this is the gate.
2. Research indie constructor feeds (e.g. Matt Gaffney's daily mini, Brendan Emmett Quigley) that publish permissive-licensed `.puz` files — these may become `openLicense` only after source-specific review confirms the license, attribution, and cache policy.
3. Contact Andrews McMeel about Universal Crossword API/syndication agreement.
4. Contact Guardian Open Platform (`open.platform@guardian.co.uk`) to confirm crossword availability and terms.
5. Approach LA Times / Tribune via official AmuseLabs API channel.

**Architecture notes:**
- Implement each source as a `PuzzleSource` subclass (Sprint 8 abstraction).
- Add source/downloader management under Settings. Do not make downloader
  discovery a primary Home affordance while the app remains local/offline-first.
- Fetched puzzles flow through the existing `ImportRepositoryImpl` pipeline (parse → duplicate check → persist) so the solve experience is identical to local imports.
- Add a `fetchedAt` / `expiresAt` cache policy respected per source row.
- Network calls: `dio` is already in the stack (see `pubspec-starter.yaml`).
- HTML parsing (Guardian): `html` package (pub.dev).
- Reference implementation: [xword-dl](https://github.com/thisisparker/xword-dl) — actively maintained Python downloader for all three sources. Use as technical reference only, not as a dependency.

**Key files to create (post Sprint 8):**
- `features/import/data/sources/universal_source.dart`
- `features/import/data/sources/guardian_source.dart`
- `features/import/data/sources/amuselabs_source.dart`
- `features/import/data/sources/indie_feed_source.dart`
- `features/settings/presentation/screens/source_management_screen.dart`

---

### #4 — Keyboard appearance causes grid/layout to shift

**Type:** Bug / UX  
**Reported:** 2026-05-04  
**Shipped:** Sprint 6 hotfix

**Description:**  
When the user taps a cell, the soft keyboard slides up and the entire solve
layout (grid + clue panel) is pushed upward to avoid being occluded. The
result is a jarring jump: the grid shrinks, shifts position, and then snaps
back when the keyboard is dismissed. On a puzzle that's already filling most
of the screen this is particularly disorienting.

**Root cause:**  
`Scaffold` defaults to `resizeToAvoidBottomInset: true`, which causes the
body to shrink by the keyboard height on every appearance/disappearance.
The grid is inside an `Expanded` widget, so it reflows each time.

**Preferred fix — keep keyboard behind the layout (overlay model):**  
Set `resizeToAvoidBottomInset: false` on the `SolveScreen` `Scaffold`.
The hidden `TextField` that drives the soft keyboard lives at `(-200, -200)`
off-screen, so the keyboard can appear without affecting layout at all.
The user sees the grid stay perfectly still; only the system keyboard
overlaps the bottom of the screen (which is acceptable — the clue panel
sits above the keyboard safe area anyway).

**Implementation notes:**
- In `SolveScreen.build()`, add `resizeToAvoidBottomInset: false` to the
  `Scaffold`.
- Verify the clue panel remains visible above the keyboard. If it gets
  clipped, wrap the `CluePanel` row in a `Padding` that adds
  `MediaQuery.of(context).viewInsets.bottom` when non-zero.
- The hidden `TextField` is positioned absolutely at `(-200, -200)` so it
  is unaffected by inset changes.
- Test by tapping a cell, typing several letters, then dismissing — the
  grid must not move at all during the keyboard animation.

**Alternative considered:**  
`KeyboardDismissBehavior.onDrag` on a wrapping `ScrollView` — rejected
because the grid is not scrollable and we do not want drag-to-dismiss
interfering with grid swipe gestures.

**Key file:** `lib/features/solve/presentation/screens/solve_screen.dart`

---

## Closed

| # | Type | Title | Shipped | Notes |
|---|------|-------|---------|-------|
| 1 | ✨ | Reset puzzle option in ⋮ menu | Sprint 5 | Confirmation dialog; clears grid, resets timer and all counters |
| 2 | ✨ | Long-press grid cell → contextual Check/Reveal menu | Sprint 6 | `onLongPressStart` in `CrosswordGrid`; `showMenu` anchored near cell |
| 4 | 🐛 | Keyboard appearance causes grid/layout to shift | Sprint 6 hotfix | `resizeToAvoidBottomInset: false` + `viewInsets.bottom` padding on clue panel |
