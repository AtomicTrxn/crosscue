# ADR-0010 — Rebus entry: NYT-aligned surfaces + first-letter acceptance

**Status:** Accepted (shipped) · **Date:** 2026 (G6, #8)
**Full design doc:** [`../rebus-entry.md`](../rebus-entry.md) (historical plan of record)

## Context

Multi-letter (rebus) cells needed an entry UX that stays discoverable without
spoiling the puzzle or breaking the one-keystroke-per-cell mental model.

## Decision

- One canonical dialog (`showRebusDialogForFocus`) reachable from three
  surfaces: an always-visible **"Rebus"** key (bottom-right of the soft
  keyboard), the cell long-press menu, and the **`Esc`** physical-keyboard
  shortcut — all NYT-aligned.
- Rebus cells are **not** visually marked (finding them is the theme).
- **First-letter acceptance:** a rebus cell accepts the full answer *or* its
  first letter, so solvers who never discover rebus mode can still finish.
  Centralized in `SolutionCell.accepts(entered)`, used by completion, check,
  and clue-correctness paths alike.
- Lightweight bidirectional rebuses via `"/"`-delimited answers (`"PB/AU"`)
  without a schema change; max input 6 characters.

## Consequences

- Completion behavior matches NYT for cross-platform solvers.
- Any new correctness check must go through `SolutionCell.accepts` — never
  string equality.
