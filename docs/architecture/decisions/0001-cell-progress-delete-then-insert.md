# ADR-0001 — Cell-progress autosave is delete-then-insert

**Status:** Accepted · **Date:** 2026 (Sprint 1)

## Context

Autosaving per-cell progress with row updates left stale `cell_progress` rows
behind when a user backtracked or reset a cell, producing phantom letters on
resume.

## Decision

`saveCellProgress` deletes the session's progress rows and re-inserts the
current state inside one transaction, rather than diffing/updating.

## Consequences

- No orphaned rows by construction; resume always reflects the saved state.
- Slightly more write volume per autosave — acceptable at grid sizes ≤ 21×21
  with the 500 ms debounce.
