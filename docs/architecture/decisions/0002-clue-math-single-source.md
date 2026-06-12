# ADR-0002 — All clue-cell math lives in `ClueProgressCalculator`

**Status:** Accepted · **Date:** 2026 (Sprint 4)

## Context

Clue-cell iteration (`_clueCells`) and word-completion checks
(`_isWordComplete`) had been duplicated across widgets and notifiers, and the
copies drifted.

## Decision

All clue-cell iteration and word-completion logic is consolidated in
`features/solve/domain/services/clue_progress_calculator.dart`
(`cellsFor(Clue)`, `isWordComplete`). Duplicating these helpers in widgets or
notifiers is a defect.

## Consequences

- One source of truth for "which cells belong to this clue" — check, reveal,
  highlight, and completion all agree.
- New solve features must call the calculator, not re-derive geometry.
