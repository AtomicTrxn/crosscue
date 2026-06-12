# ADR-0004 — Typed load errors are plain sealed classes

**Status:** Accepted · **Date:** 2026 (Sprint 4)

## Context

Solve-screen load failures needed exhaustively-switchable error types.
Freezed unions work but add codegen weight for types that carry little data.

## Decision

`SolveLoadError` and its subtypes (`PuzzleNotFoundError`,
`SolveSessionLoadError`) are hand-written **plain sealed classes** in
`solve/domain/models/solve_errors.dart`. Presentation switches exhaustively:
`switch (e) { PuzzleNotFoundError() => ..., ... }`. The same pattern was later
reused for `SyncState`.

## Consequences

- Exhaustiveness checking without build_runner involvement.
- Convention: sealed hierarchies that are mostly *tags* stay plain Dart;
  Freezed is for data-carrying value objects (see `CONVENTIONS.md`).
