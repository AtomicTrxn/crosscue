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
- Add a `DownloaderScreen` or `HomeScreen` "Browse sources" entry point.
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
- `features/import/presentation/screens/browse_sources_screen.dart`

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
