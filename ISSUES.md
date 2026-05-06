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
| 5 | ✨ | Solve screen: replace ClueBar header with inline word highlight only | Next | Remove the AppBar-adjacent clue text header; the active/cross clue bar above the keyboard is the sole hint surface. Repeated tap on same cell toggles across↔down. See detail. |
| 6 | ✨ | Keyboard: larger keys for finger-friendly tapping | Next | Increase key height and font size; see detail for spec deltas |
| 7 | ✨ | Completed words/letters: soft green fill color | Next | Apply a muted green (`#C8E6C9` bg / `#2E7D32` text) to fully correct words; distinct from the check-correct state |
| 8 | 🐛 | Settings → How to Play does not launch onboarding | Next | Tapping "How to Play" in Settings should push `OnboardingScreen` via `context.push(Routes.onboarding)` |
| 9 | ✨ | About screen: icon + description + GitHub link | Next | Currently a stub. Add app icon, 2-line tagline, version string, and a tappable GitHub URL. See detail. |
| 10 | 🐛 | Export and import data not implemented or wired up | Backlog | "Export data" and "Import data" in Settings show a stub toast. Needs design decision on format (JSON dump of DB?) before implementing. |
| 11 | ✨ | Clear data modal: cancel button larger and blue | Next | The cancel button in the "Clear All Data" confirmation dialog should be the same size/style as the destructive button but in `#1565C0` blue |
| 12 | 🐛 | Crash reporting saves nothing — wire up local log | Next | `CrashReporter` is a no-op stub. Phase 1 target: capture crash/error details to a local file in `getApplicationDocumentsDirectory()`. No transmission yet. See detail. |
| 13 | 🐛 | Colorblind mode toggle has no effect | Backlog | Setting is persisted but `CrosswordTheme` / `CrosswordGridPainter` do not read it. Define alternate palette and gate on the provider. |
| 14 | 🐛 | Sounds setting has no effect | Backlog | Toggle is persisted but no audio is played anywhere. Needs `audioplayers` or `just_audio` package + sound asset decisions before implementing. |
| 15 | ✨ | Reveal puzzle dialog: cancel button blue | Next | Cancel in the "Reveal Puzzle" confirmation dialog should be blue (`#1565C0`), matching the primary action style, so both buttons are visually equal weight |
| 16 | 🐛 | Revealing entire puzzle does not mark puzzle as complete | Next | `SolveNotifier.revealGrid()` fills all cells but `_checkCompletion()` is not called afterward. Should set status to `PuzzleStatus.revealed` and trigger completion sheet. |
| 17 | ✨ | Clue panel: auto-center active clue and tappable rows | Next | Scroll active clue to center of visible list on focus change. Tapping any clue row should move focus to that word's first empty cell. See detail. |
| 18 | ✨ | Clue panel: larger font, show only 5 clues | Next | Increase clue text from current size to `14px`; limit visible rows to 5 (across + down combined) to free vertical space for larger keyboard keys. See detail. |

---

## Detail

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
2. Research indie constructor feeds (e.g. Matt Gaffney's daily mini, Brendan Emmett Quigley) that publish permissive-licensed `.puz` files — these are `openLicense` and can ship without further legal review.
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
