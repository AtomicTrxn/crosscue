# Rebus Entry (G6) — Implementation Plan

> Tracks [#8 (G6)](https://github.com/AtomicTrxn/crosscue/issues/8): _Rebus entry — editable multi-letter cells._
> Companion doc to `ARCHITECTURE.md`. Status: planning.

## 1. Goal

Let a solver type more than one letter into a single grid cell so puzzles
with rebus squares (e.g. a "THE" or "EST" cell) can actually be solved
from the UI. Stay consistent with existing solve mechanics (focus
advance, check/reveal, autosave, sync, completion detection) and stay
discoverable for users who have never met a rebus before.

## 2. Current state (audit)

What already works:

- **Parser**: `puz_parser.dart` and `ipuz_parser.dart` both decode rebus
  squares from `GRBS`/`RTBL` (and the ipuz map form) into
  `SolutionCell.solution` as a multi-character string (e.g. `"EST"`).
  Covered by `puz_parser_test.dart` and `ipuz_parser_test.dart`.
- **Domain model**: `CellProgress.letter` is already a `String` — no
  schema change is needed to hold a multi-letter answer. The DB row
  (Drift JSON serialization of `Grid<CellProgress>`) also already
  stores it as a string.
- **Enum**: `EntryMode { normal, pencil, rebus }` is defined but
  currently unused at runtime.
- **Notifier**: `SolveNotifier.inputRebus(value)` exists, normalizes to
  uppercase A–Z, requires `length >= 2`, writes one cell, advances
  focus once (same as a single letter), schedules save, runs the
  completion check. Covered by `solve_notifier_test.dart`.
- **Long-press menu**: `crossword_grid_input.dart` has an "Enter rebus"
  item that opens an `AlertDialog` with a `TextField`. This works but
  is the **only** entry point and almost no first-time user will find
  it.
- **Completion**: `_checkCompletion()` already compares whole strings
  (`prog.letter.toUpperCase() == cell.solution.toUpperCase()`), so
  multi-char answers complete the puzzle correctly today.
- **Check / reveal**: `GridProgressMutator.checkCells` compares whole
  strings; `revealCells` writes the full `solution` string. Both work
  for rebus today.

What is missing:

1. **Discoverability.** Entry is buried under long-press → submenu.
2. **Rendering.** `CrosswordGridPainter._paintLetter` uses a fixed
   font-size factor with `clamp(10, 32)` and a `maxWidth` of one cell
   width. Multi-character strings render but clip / look cramped — no
   autoshrink, no fitting.
3. **Soft-keyboard affordance.** The custom `CrosswordKeyboard` has no
   way to open the rebus dialog; soft-keyboard-only users (the iOS/
   Android default) cannot use the feature at all.
4. **Backspace semantics on a multi-letter cell.** Today, one
   `backspace()` call clears the entire `letter` field. Reasonable, but
   undocumented and worth confirming behavior matches user mental
   model.
5. **State signals.** No visual distinction between a normal cell and
   a rebus-eligible cell, and no signal that a cell currently holds a
   rebus answer beyond visually-cramped text.
6. **Tests** for keyboard-driven rebus flow, autoshrink rendering, and
   reset/clear behavior.

## 3. Design principles

Guiding tradeoffs, in priority order:

1. **Don't spoil the puzzle.** Standard crossword convention (NYT,
   Crosshare, AcrossLite) is that rebus cells are _not_ visually
   marked in the grid — finding them is part of the theme. We follow
   this. No badges, no different border on cells whose `solution.length
   > 1`.
2. **Preserve the one-keystroke-per-cell mental model.** Typing a
   letter on the soft/physical keyboard must continue to overwrite the
   focused cell with that single letter. Rebus entry has to be an
   _explicit_ mode change, not an implicit "type a second letter into
   the same cell" gesture. (Implicit append would break the
   overwrite-and-advance behavior every user has internalized.)
3. **One canonical entry point, surfaced everywhere.** A single
   `_showRebusDialog` UI, reachable from at least: long-press menu
   (today), a soft-keyboard "Rebus" key, and a physical-keyboard
   shortcut. All three call the same method, identical normalization.
4. **Stay within existing architecture layers.** No new domain models.
   Add a notifier method only if behavior changes. Visual changes are
   confined to the painter and keyboard widget.
5. **Graceful fallback for users who never use rebus.** Most puzzles
   have no rebus cells; the soft-keyboard affordance must not steal
   space or attention in the common case. Either (a) only show when
   the puzzle contains at least one rebus square, or (b) keep it
   present but small.

## 4. Recommended UX

### 4.1 Soft-keyboard "Rebus" key (the primary surface)

The NYT pattern, as described in [their own explainer][nyt]:

- **iOS:** Tap a cell. Tap "More" on the bottom-LEFT of the keyboard
  (a layer toggle into a numbers/symbols keyboard). The "Rebus" key
  appears on the bottom-RIGHT of that secondary layer. Tap it →
  expanding text field opens over the cell. Type letters. Tap
  anywhere inside the grid to close and save.
- **Android:** Same flow, but the layer toggle is an "Ellipsis key
  […]" on the lower-LEFT (the toggle, not the rebus button itself).
- **Web:** "Rebus" lives on a toolbar above the clue lists. The
  keyboard shortcut is `Esc`. Inside the dialog, `Enter`/`Return`
  saves; `Esc` cancels.

Two takeaways for our design:

1. The **labeled "Rebus" button** is the consistent surface across
   all three NYT platforms — not a glyph like `…`. The `…` users
   may remember on Android is the *layer toggle*, not the rebus
   button.
2. NYT routes it through a two-tap path (More → Rebus) because their
   keyboard hosts two layers (letters; numbers/symbols). Our
   `CrosswordKeyboard` is single-layer (alphabet only). A two-tap
   path would be friction without benefit.

**Decision:** put a single, always-visible key **labeled "Rebus"** on
the bottom row of our soft keyboard. One tap opens the dialog. This
is strictly fewer taps than NYT, uses NYT's actual visible label so
NYT-trained users recognize it, and keeps the principle-3.1 "don't
spoil" property (the key is on every puzzle so its presence leaks
nothing).

[nyt]: https://www.nytimes.com/2023/12/08/crosswords/rebus-crossword-puzzle.html

**Keyboard layout change.** Current bottom row:

```
⌫ Z X C V B N M ✓
```

Proposed bottom row (insert a "Rebus" `_SpecialKey` to the right of
`✓` so the rebus key is the bottom-right-most element, matching
NYT's bottom-right convention):

```
⌫ Z X C V B N M ✓ Rebus
```

The Rebus key is wider than a letter key (matches `_SpecialKey`'s
existing `unit * 1.3` width to fit the four-letter label). `✓`
(check word) stays — it's a Crosscue-specific affordance NYT
doesn't have. The seven bottom-row letter keys narrow slightly; this
is the lowest-density row so the impact is acceptable.

If user testing shows the layout is too crowded, fall back to placing
"Rebus" immediately right of `⌫`:

```
⌫ Rebus Z X C V B N M ✓
```

Either way, the key is present on **every** puzzle.

**Wiring.** Add `VoidCallback onRebus` to `CrosswordKeyboard` (no
visibility flag) and route the tap through the same shared dialog
helper used by long-press and the physical-keyboard shortcut.

### 4.2 Long-press menu (kept)

Today's "Enter rebus" item in the long-press popup stays exactly as-is.
It is the discoverable surface for power users and the only surface on
desktop where there's no soft keyboard.

### 4.3 Physical keyboard shortcut

Use `Esc` to open the rebus dialog on the current focused cell —
matching NYT's web shortcut exactly. Pressing `Esc` *inside* the
dialog cancels (also matching NYT). The dual role of `Esc` is
internally consistent: "switch into rebus mode" on the grid, "switch
out of rebus mode" in the dialog.

Implement in `_onKeyEvent`: branch on `LogicalKeyboardKey.escape` →
call the shared `showRebusDialogForFocus` helper.

### 4.4 The rebus dialog itself (refinements)

Today's `AlertDialog` is functional. Aligning with NYT conventions:

- **Pre-fill** the field with the cell's current letter, single-char
  or multi-char (currently only pre-filled when length > 1). Lets
  the user "promote" a single letter into a rebus by appending.
- **Validate on submit:** empty string → close without changes;
  single character → call `inputLetter()` (so the cell behaves
  identically to a normal entry); two or more → call `inputRebus()`.
  This is the only place we round-trip between the two entry methods.
- **Title:** keep "Enter rebus". Hint text: "Type 1+ letters for
  this cell".
- **Cap input at 6 letters** (real-world rebuses top out at 5 across
  major construction tools; one buffer for exotic cases).
- **Dismissal:** keep the existing `Enter`/`Cancel` buttons; `Esc`
  cancels (Flutter default for `AlertDialog`). Optionally also
  commit-and-close on tap-outside (`barrierDismissible: true` with
  a `WillPopScope` that submits the current text) to match NYT's
  "tap anywhere inside the grid to close and save" behavior. Defer
  this until after the buttons ship — the buttons are more
  discoverable for first-time users.

### 4.5 Rendering — autoshrink, never spill

`CrosswordGridPainter._paintLetter` needs to fit multi-character text
in a single cell without changing cell size. Change:

- Compute the base font size as today.
- If `letter.length > 1`, scale font size down by
  `min(1.0, cellSize * factor / measuredWidth)` so the glyphs fit the
  cell width minus a small padding. Floor at 8.0 to remain legible —
  if even 8.0 doesn't fit (5–6 letter rebus in a 7×7 mini), fall back
  to a 7.0 floor and accept slight crowding.
- Reduce font weight from `bold` to `w600` for `length >= 3` to
  visually relieve density.
- No other change to color / state glyph / accessibility overlays —
  multi-character cells participate in `checkedCorrect`,
  `checkedIncorrect`, and `revealed` exactly like single-letter cells.

Edge case: the `entry` animation (`scale: 0.7 + 0.3 * effectValue`)
multiplies into the autoshrink. Use the *autoshrunk* font size as the
base, then apply the animation scale, so multi-letter cells still
animate proportionally without overflowing at peak.

### 4.6 First-letter acceptance (the forgiving completion rule)

**Important finding from the [NYT article][nyt]:** NYT accepts *either*
the full rebus string *or* just its first letter as a valid answer.
From the JACK example:

> "JACK works for both the Across and Down entries, and the following
> rebus answers would be accepted: JACK, J (The first letter)"

This is a deliberate accessibility choice: a solver who never
discovers rebus mode can still complete the puzzle. The cluing still
works ("LUMBERJ" makes no sense, but the grid is accepted as solved).

**Recommendation: adopt the same rule.** Three reasons:

1. **Intuitiveness.** A user who doesn't know rebus exists is not
   punished. The "Rebus" key is a power tool for solvers who want to
   honor the puzzle's full intent; it's not a gate that locks
   completion behind a feature they may not have found.
2. **Consistency with NYT.** Users who solve on both platforms see the
   same completion behavior.
3. **Composes cleanly with our existing code.** The change is local
   to `_checkCompletion` in `solve_notifier.dart` and `checkCells` in
   `grid_progress_mutator.dart`. No model changes.

**Implementation sketch.** Replace strict equality in the two checking
sites with a helper:

```dart
bool _matchesSolution(String entered, String solution) {
  if (entered.isEmpty) return false;
  final e = entered.toUpperCase();
  final s = solution.toUpperCase();
  if (e == s) return true;
  // Rebus cells: first letter alone also counts.
  if (s.length > 1 && e.length == 1 && e == s[0]) return true;
  return false;
}
```

Used in `_checkCompletion` (completion) and in `checkCells` (the
check-letter / check-word actions). Reveal stays as-is — revealing
writes the full canonical answer.

**Implications:**

- The check-letter glyph on a rebus cell with just the first letter
  shows `checkedCorrect`, matching the completion rule.
- The crossing word for a rebus cell now has a single-letter
  candidate that passes — this is *intentional* and matches NYT.
- Stats and personal-best detection are unaffected (they read
  `status.isTerminal`, which fires once `_checkCompletion` passes).

### 4.7 Backspace semantics

- A single `backspace()` on a multi-letter cell clears the **whole**
  cell (current behavior). This matches how the cell appears: one
  visual unit.
- Document this in the rebus dialog hint text ("Backspace clears the
  whole cell").
- Do **not** add a per-letter shrink-from-the-right behavior —
  inconsistent with the "one cell = one answer" model and complicates
  focus navigation.

## 5. Implementation phases

### Phase A — Rendering (no behavior changes)

Goal: existing rebus entries (via long-press) render correctly.

- `crossword_grid_painter.dart`
  - Extract a small helper `_fitFontSize(letter, cellSize)` returning
    a font size that fits the cell.
  - Use it in `_paintLetter` and in the backspace-fade branch.
- Add a golden test or widget test that renders a cell with letter
  `"EST"` at three cell sizes (small mini, medium, large) and asserts
  no clipping.

### Phase B — Soft keyboard affordance

- `crossword_keyboard.dart`
  - Add a required `VoidCallback onRebus` constructor param (no
    visibility flag — the key is always shown, matching NYT).
  - Render a "Rebus" `_SpecialKey` to the right of `✓` in the bottom
    row. Width matches the existing `unit * 1.3` used by `⌫` / `✓`.
    Pick a neutral background (`xwTheme.keyDefault` so it reads as
    "extra letter input" rather than as a destructive or affirmative
    action — distinct from both `⌫` and `✓`).
  - Use a 12–13 px label so the four-letter "Rebus" string fits.
  - Recompute the bottom-row width math: there are now 7 letter
    keys + 3 specials in the layout calculation (was 7 + 2).
- `solve_screen.dart`
  - Lift `_showRebusDialog` (currently on `_CrosswordGridState` as a
    private helper) into a shared top-level helper
    `showRebusDialogForFocus(BuildContext, WidgetRef, puzzleId)` that
    reads the current focus from the notifier, dispatches the dialog,
    and routes the result through `inputLetter` / `inputRebus` per
    §4.4. Call it from both the long-press menu path and the new
    keyboard `onRebus` callback.

> Note: a `hasRebusSquares` derived state on `SolveState` is **not**
> needed under the NYT-style always-visible rule. We avoid the
> derived getter entirely.

### Phase C — Notifier refinements + first-letter acceptance

- `solve_notifier.dart`
  - Tighten `inputRebus`: if input length is 1, delegate to
    `inputLetter` (preserves dialog → normal-entry round-trip).
  - Clamp input at 6 characters (`upper.substring(0, min(upper.length, 6))`).
  - Replace strict equality in `_checkCompletion` with the
    `_matchesSolution` helper (§4.6).
- `grid_progress_mutator.dart`
  - Use the same `_matchesSolution` helper in `checkCells` so the
    check-letter / check-word actions agree with completion logic on
    rebus cells.
- Add unit tests:
  - `inputRebus`: empty (no-op), single-char (delegates to inputLetter),
    multi-char (today's behavior), over-cap (truncates).
  - Completion accepts `"J"` in a `"JACK"` cell (per §4.6).
  - `checkCells` marks `"J"` in a `"JACK"` cell as `checkedCorrect`.

### Phase D — Physical keyboard shortcut

- `crossword_grid_input.dart::_onKeyEvent`
  - On `LogicalKeyboardKey.escape`, call the shared
    `showRebusDialogForFocus` helper (matches NYT web). The dialog
    itself uses Flutter's default `Esc`-cancels behavior, so the
    dual-role mapping just works.

### Phase E — Documentation & tests

- Update `ARCHITECTURE.md`: under "Feature: solve", mention rebus entry
  surfaces (keyboard "…" key, long-press, dialog) and the `hasRebusSquares`
  derived state.
- Move issue #8 out of deferred → in progress → done.
- New tests:
  - `solve_notifier_test.dart`: cover the empty / 1-char / >6-char
    paths of `inputRebus`.
  - `crossword_keyboard_test.dart` (new): rebus key shown iff
    `showRebus` is true; tap fires callback.
  - `solve_state_test.dart` (or wherever derived state is tested): add
    a `hasRebusSquares` case for a puzzle with and without a rebus cell.
  - `solve_screen_widget_test.dart`: rebus key appears only for the
    rebus3x3 fixture, not for the plain fixture.
  - Golden / pixel test for multi-letter rendering at three cell sizes.

## 6. File-by-file change list

| File | Change |
|---|---|
| `lib/features/solve/presentation/widgets/crossword_grid_painter.dart` | `_fitFontSize` helper; use in `_paintLetter`. |
| `lib/features/solve/presentation/widgets/crossword_keyboard.dart` | New required `onRebus`; insert "Rebus" `_SpecialKey` to the right of `✓`; recompute bottom-row width math. |
| `lib/features/solve/presentation/widgets/crossword_grid_input.dart` | Pre-fill dialog with single-char letters; route 1-char input through `inputLetter`; cap at 6; add `Esc` shortcut in `_onKeyEvent`. |
| `lib/features/solve/presentation/screens/solve_screen.dart` | Pass `onRebus` into `CrosswordKeyboard`; lift `_showRebusDialog` into a shared `showRebusDialogForFocus` helper used by all three surfaces (long-press, keyboard `Rebus` key, `Esc`). |
| `lib/features/solve/presentation/notifiers/solve_notifier.dart` | `inputRebus` delegates on 1-char input; clamps at 6 chars; `_checkCompletion` uses `_matchesSolution` to accept first-letter answers. |
| `lib/features/solve/domain/services/grid_progress_mutator.dart` | `checkCells` uses the same `_matchesSolution` helper so check/letter feedback agrees with completion. |
| `test/...` | See Phase E. |
| `ARCHITECTURE.md` | One paragraph under "Feature: solve". |

No changes to:
- Domain models (`CellProgress`, `SolutionCell`, `EntryMode`).
- Database schema or DAOs (`CellProgress.letter` is already `String`).
- Sync layer (the sessions namespace serializes whatever string is in
  the cell — see `docs/architecture/sync-design.md`).
- Parsers.

## 7. Resolved decisions

- **Rebus key surface.** Always-visible "Rebus"-labeled key, bottom-
  right of the soft keyboard (matches NYT's actual button label and
  position; see [the Times' own explainer][nyt]). One-tap rather than
  NYT's two-step (More → Rebus) because we have a single-layer
  keyboard. ✅
- **Don't mark rebus cells in the grid.** Convention-aligned; finding
  them is part of the theme. NYT explicitly: *"Aren't we supposed to
  be warned when a rebus exists in the puzzle? No, that's part of the
  fun of solving."* ✅
- **Rebus is an explicit mode.** Single keystrokes always overwrite;
  rebus entry is reachable only through the "Rebus" key, the long-
  press menu, or `Esc`. ✅
- **Physical-keyboard shortcut.** `Esc` opens the rebus dialog;
  `Esc` inside the dialog cancels (NYT web pattern). ✅
- **First-letter acceptance.** A rebus cell accepts either the full
  solution or its first letter (§4.6). Matches NYT and protects
  users who never discover rebus mode. ✅
- **Dialog round-trip safety.** A 1-character submission delegates to
  `inputLetter`; an empty submission is a no-op; the dialog is never
  a dead end. ✅
- **Max rebus length.** 6 characters. ✅

## 8. Open questions

1. **Keyboard slot for "Rebus".** Primary recommendation: right of
   `✓`, making "Rebus" the bottom-right-most key (matches NYT
   position exactly). Fallback if that crowds `✓`: between `⌫` and
   `Z`. Worth a quick visual prototype on both small and mini
   puzzles.
2. **"Tap outside to save" dismissal.** NYT's web/iOS pattern is
   tap-outside saves. Our `AlertDialog` currently has explicit
   buttons. Add tap-to-save now, or defer? Recommendation: defer —
   the buttons are more discoverable. Revisit after users have lived
   with the feature.
3. **Bidirectional rebuses** (different Across vs Down answer in the
   same cell, e.g. NYT's PB/AU alchemy puzzle). Out of scope for
   this issue — see §9.
4. **Pencil-rebus interaction.** Out of scope; revisit when pencil
   mode itself ships.
5. **Entry animation.** Play the existing cell-entry animation once
   for the whole word (not per character). Matches "one cell = one
   answer".

## 9. Out of scope

- **Bidirectional rebuses** (NYT's PB-across / AU-down pattern).
  Requires a per-direction solution field on `SolutionCell` and a
  parser path that recognizes the construction. `.puz` files don't
  encode it standardly; iPuz can. Track as a separate issue.
- **Symbol/numeric rebuses** (a "❤" or "1" representing a word).
  Our `_letterFilterRe` strips non-A–Z; keep that for now. The puzzle
  file formats already preserve arbitrary strings in `SolutionCell.
  solution`, so widening later is non-breaking.
- **Per-cell pencil marks inside a rebus cell.**
- **A rebus tutorial / first-run coachmark.** Defer until we observe
  whether users find the "Rebus" key. The combination of always-
  visible button + first-letter-acceptance fallback should make a
  tutorial unnecessary for most users.
- **Reverse-engineering display tricks** (e.g. shrinking the letter
  inside a circle annotation differently). Use the same autoshrink
  path as plain rebus cells.

## 10. Risk / consistency checklist

- [ ] Completion check still passes for the existing rebus fixture
      after Phase B (no regression in `_checkCompletion`).
- [ ] Completion accepts the first letter alone in a rebus cell
      (new behavior, §4.6) — add an explicit test using the rebus3x3
      fixture.
- [ ] `checkCells` agrees with completion: a single letter that
      matches the rebus's first character is marked
      `checkedCorrect`, not `checkedIncorrect`.
- [ ] Reveal on a rebus cell writes the full canonical answer
      (existing behavior); confirm it overwrites a prior first-letter-
      only entry.
- [ ] Backspace on a multi-letter cell clears the whole cell and then
      retreats on the next press — already true; add a unit test to
      lock it.
- [ ] Autosave writes the full string and `createOrResumeSession`
      reads it back unchanged.
- [ ] Sync round-trip: a rebus session synced to iCloud / Drive
      restores the multi-letter cell on a second device. Extend the
      sessions-namespace fixture to include a multi-letter cell.
- [ ] Esc on grid opens the dialog; Esc in dialog cancels (no leaking
      Esc keystrokes back to the focus node).
