# Research Topic #11 — Game Mechanics & Input Feedback

Status: Resolved
Implementation Status: 🔄 Partially Implemented — letter input, auto-advance, check/reveal, counters, and completion types shipped by Sprint 5; hint/rebus/pencil enhancements remain deferred
Owner: Codex

## Research Question

What game mechanics should govern letter entry, auto-advance, hinting, checking, revealing, mistake feedback, completion, stats, and accessibility feedback?

## Decision To Unblock

Which gameplay rules need to be fixed before implementing the puzzle engine, grid UI, persistence model, and accessibility semantics?

## Recommendation

Create a dedicated `PuzzleInteractionPolicy` / `GameRules` layer separate from rendering. The UI should ask this policy what happens when the user types, deletes, checks, reveals, switches direction, enters a rebus, or completes a puzzle. This avoids scattering rules across the canvas painter, keyboard, state notifier, and stats code.

Default posture: be helpful but calm. Entering a letter should feel instant and satisfying, but correctness feedback should only appear when the user explicitly asks to check/reveal or when the puzzle is completed. Avoid always-on wrong-letter feedback by default; it changes the solving experience from a crossword into a quiz.

## Mechanics Scope

This spec owns:

- Letter placement behavior.
- Auto-advance behavior.
- Delete/backspace behavior.
- Direction switching.
- Check/reveal/hint actions.
- Rebus/multi-character cell entry.
- Mistake, checked, and revealed state.
- Completion validation.
- Stats/streak effects of hints.
- UI animation/haptic feedback for gameplay actions.
- Accessibility feedback text for gameplay actions.

This spec does not own:

- Visual theme tokens; see topic #10.
- Canvas semantics implementation details; see topic #3.
- Persistence schema; see topic #2.

## Core State Model

Use these state concepts in the engine:

| Concept | Meaning |
|---------|---------|
| `guess` | Current user-entered value for a playable cell; `null` means empty. |
| `entryMode` | `normal`, `pencil`, or `rebus`. Pencil can be deferred if MVP scope needs trimming. |
| `cellState` | `empty`, `filled`, `checkedCorrect`, `checkedIncorrect`, `revealed`. |
| `wasChecked` | Whether any check action touched this cell. |
| `wasRevealed` | Whether reveal filled or confirmed this cell. |
| `mistakeCount` | Count of explicit incorrect check results, not passive wrong guesses. |
| `checkCount` | Count of user-triggered check actions. |
| `revealCount` | Count of user-triggered reveal actions. |
| `cleanSolveEligible` | False after any reveal; optionally false after any check depending on stats rules. |

## Letter Placement

### Normal Letter Entry

When the user enters A-Z in a normal cell:

1. Replace the current `guess` with the uppercase letter.
2. Set `cellState` to `filled` unless the cell was previously `revealed`.
3. Push an undo snapshot.
4. Persist progress.
5. Play letter-entry animation and light haptic if enabled.
6. Advance focus according to movement strategy.

Do not automatically mark the letter correct/incorrect during normal entry.

### Replacing A Letter

If the focused cell already has a non-revealed guess:

- Typing a new letter replaces it.
- Advance behavior should follow the current movement strategy.
- If the cell was `checkedIncorrect`, replacing the value clears it back to `filled`.
- If the cell was `checkedCorrect`, replacing should be allowed only if the user has not locked checked-correct cells. MVP default: allow replacement and clear to `filled`.
- If the cell was `revealed`, default: do not allow replacement unless the user explicitly enables editing revealed cells in settings.

### Rebus Entry

MVP can support rebus answers in the data model while deferring full rebus UI if needed.

Recommended behavior:

- Long-press cell or keyboard `Rebus` key opens a small input sheet.
- Rebus guess is stored as full uppercase string.
- Display shortened visual text in cell if necessary, but screen reader value should say the full rebus.
- Auto-advance after committing rebus.
- Check/reveal compares the full string, not the visual abbreviation.

## Movement Strategy

Default behavior:

| Action | Behavior |
|--------|----------|
| Tap focused cell | Toggle direction. |
| Tap different cell | Move focus to that cell; direction remains unless only one word exists at that cell. |
| Type letter | Advance to next unfilled cell in current word. |
| Current word filled | Advance to next clue with empty cells. |
| Backspace on filled cell | Clear current cell; stay on cell. |
| Backspace on empty cell | Move to previous editable cell and clear it if filled. |
| Arrow keys | Move one cell in arrow direction, skipping black cells. |
| Space / Tab | Toggle direction or advance clue, depending on platform keyboard conventions. |

Settings candidate:

- `Skip filled cells`: off by default.
- `Stop at end of word`: off by default.

## Check Actions

Check actions verify guesses without filling answers.

| Action | Scope | Result |
|--------|-------|--------|
| Check letter | Focused cell | Marks current guess `checkedCorrect` or `checkedIncorrect`; empty cell does nothing or prompts "No letter to check." |
| Check word | Active word | Marks filled cells correct/incorrect; empty cells remain empty. |
| Check puzzle | Whole puzzle | Marks filled cells correct/incorrect; empty cells remain empty. |

Recommended rules:

- Checking increments `checkCount`.
- Incorrect checked cells increment `mistakeCount` once per cell per distinct wrong value, not every time the user taps Check.
- A checked-correct cell can still be edited unless a future setting locks it.
- Replacing a checked-incorrect value clears the incorrect state.
- Checking should never fill answers.

Stats impact:

- `usedCheck = true` after any check action.
- A solve with checks can still count as completed/streak-preserving.
- "Clean solve" or personal-best badges should require no checks and no reveals.

## Reveal / Hint Actions

Reveal actions fill answers and should be treated as hints.

| Action | Scope | Result |
|--------|-------|--------|
| Reveal letter | Focused cell | Fills solution for that cell, marks `revealed`. |
| Reveal word | Active word | Fills all cells in active word, marks them `revealed`. |
| Reveal puzzle | Whole puzzle | Fills all cells, marks them `revealed`, puzzle enters reviewed/revealed state rather than clean solved. |

Recommended rules:

- Revealed cells are visually distinct and remain marked.
- Revealing increments `revealCount`.
- Any reveal sets `cleanSolveEligible = false`.
- A puzzle completed with reveals may count as finished, but should be labeled `Solved with help` or `Completed with reveals`.
- Revealing the whole puzzle should not count toward streak unless the product intentionally allows assisted streaks. Current lean: reveal puzzle does not preserve streak; reveal letter/word preserves completion but disqualifies clean stats.

Open decision for user/product:

- Should any reveal break streak, or only reveal puzzle? Current recommendation: only reveal puzzle breaks streak; smaller hints disqualify clean solve but still let casual users maintain habit.

## Completion Validation

When the grid has no empty playable cells:

1. Validate all guesses against the solution.
2. If all correct:
   - Set status to `solved` or `solvedWithHelp`.
   - Stop timer.
   - Persist completion.
   - Show completion animation/stats.
3. If any incorrect:
   - Do not auto-mark all wrong cells by default.
   - Give a gentle "Something's not quite right" message.
   - Offer `Check puzzle` as an explicit action.

Rationale: silent wrongness is confusing, but auto-exposing every incorrect cell removes too much agency.

## UI Feedback Matrix

| Event | Visual Feedback | Haptic | Sound | Accessibility |
|-------|-----------------|--------|-------|---------------|
| Cell focus | Active cell fade, active word highlight | Selection click optional | None | Announce cell/clue via semantics. |
| Letter entered | Letter fade/scale, focus advance | Light impact | None by default | Updated cell value; no live announcement unless focus changes. |
| Backspace | Letter fade out | Selection click | None | Updated cell value. |
| Direction toggle | Word highlight cross-fade | Selection click | None | Announce direction/clue. |
| Check correct | Cell flips/pulses green briefly | Light impact | None | Value includes "checked correct." |
| Check incorrect | Cell shake + red state | Short vibration | None | Value includes "marked incorrect." |
| Reveal | Cell flip to revealed state | Medium impact | None | Value includes "revealed letter A." |
| Word complete | Subtle word pulse when all cells in the word are filled (any letter) | Medium impact optional | None | No forced announcement; pulse signals fill, not correctness. |
| Puzzle solved | Completion animation + stats | Celebration pattern optional | Optional off by default | Dialog/live region with solve result. |

Respect reduced-motion and haptics settings. If reduced motion is enabled, replace flips/shakes with short color/state changes.

## Hint UI

Expose hints from an overflow or toolbar menu:

- Check letter.
- Check word.
- Check puzzle.
- Reveal letter.
- Reveal word.
- Reveal puzzle.

Before destructive/high-impact actions:

- `Reveal word`: no confirmation needed.
- `Reveal puzzle`: confirm because it ends meaningful solving.
- `Check puzzle`: no confirmation needed.

Suggested copy:

- `Check letter`
- `Check word`
- `Reveal letter`
- `Reveal word`
- `Reveal puzzle`
- `This will fill the whole puzzle. Continue?`

Avoid moralizing copy like "Give up?"

## Stats And Solve Labels

| Condition | Label | Streak | Personal Best |
|-----------|-------|--------|---------------|
| No checks, no reveals | Clean solve | Counts | Eligible |
| Checks used, no reveals | Solved with checks | Counts | Not eligible for clean PB |
| Reveal letter/word used | Solved with hints | Counts by current lean | Not eligible |
| Reveal puzzle used | Revealed | Does not count by current lean | Not eligible |

This should be revisited once the streak philosophy is finalized.

## Persistence Implications

Topic #2 should store or derive:

- `check_count`
- `reveal_count`
- `mistake_count`
- `used_check`
- `used_reveal`
- `clean_solve_eligible`
- `completion_type`: `clean`, `checked`, `hinted`, `revealed`

Per-cell progress should track:

- `guess`
- `state`
- `was_checked`
- `was_revealed`
- `last_wrong_guess_hash` or equivalent if mistake counting needs deduping without storing old guesses.

Avoid storing detailed guess history long-term unless undo persistence becomes a requirement.

## Accessibility Requirements

- Every check/reveal action must be available to screen reader users from normal controls, not only gestures.
- Cell semantics value should include `empty`, `letter A`, `marked incorrect`, `checked correct`, or `revealed letter A`.
- Completion should use a dialog or polite live region.
- Wrong-letter feedback should not rely only on color or shake; include icon/state and semantics.
- Rebus entry must announce the full value, not just abbreviated cell text.

## Open Decisions For User/Product

| Decision | Current Lean | Notes |
|----------|--------------|-------|
| Does reveal letter/word break streak? | No | Keeps habit-friendly feel; still disqualifies clean stats. |
| Does reveal puzzle break streak? | Yes | A fully revealed puzzle is not really solved. |
| Should checks disqualify personal best? | Yes for clean PB | Can still show best assisted time separately later. |
| Pencil mode in MVP? | Defer unless strongly desired | Adds UI/state complexity. |
| Lock checked-correct cells? | No | Let users edit; advanced setting can come later. |
| Always-on incorrect feedback? | No | Only explicit check/reveal or final validation. |
| Word-complete pulse requires correctness? | No — fires on fill | Pulse fires when all cells in the word are filled (any letter), not only when correct. Avoids an implicit correctness signal during normal play. Medium haptic is optional alongside the visual pulse. |

## Implementation Checklist

1. Add `GameRules` / `PuzzleInteractionPolicy` interface before implementing the grid.
2. Implement commands: `enterLetter`, `delete`, `toggleDirection`, `checkLetter`, `checkWord`, `checkPuzzle`, `revealLetter`, `revealWord`, `revealPuzzle`, `enterRebus`.
3. Make each command return a `PuzzleInteractionResult` containing state changes plus UI feedback hints.
4. Keep animations/haptics in UI, but drive them from command results.
5. Persist progress after every command that mutates state.
6. Add unit tests for movement, check/reveal, completion labels, and stats effects.
7. Add accessibility tests/QA for check/reveal controls and cell semantics.
8. Revisit streak/reveal decisions with product owner before implementation locks.

## Sources

- Internal architecture notes: [architecture-design-review.md](../docs/archive/architecture-design-review.md)
- Design/UX feedback guidance: [topic-10-design-ux-research.md](topic-10-design-ux-research.md)
- Canvas accessibility semantics: [topic-03-canvas-accessibility.md](topic-03-canvas-accessibility.md)
- Persistence schema: [topic-02-drift-database-schema.md](topic-02-drift-database-schema.md)
