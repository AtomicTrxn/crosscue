# ADR-0008 — Completion data: hybrid model with named authorities

**Status:** Accepted · **Date:** 2026-05 (Sprint E; closes #59)
**Full design doc:** [`../completion-authority.md`](../completion-authority.md)

## Context

Completion state lived in three places (in-memory `SolveState`,
`solve_sessions`, `puzzle_completions`) with undocumented ownership and a few
divergence windows.

## Decision

Adopt the hybrid model with **named authorities** (Option C of the design
doc):

1. In-memory `SolveState` owns the **live** solve; only `SolveNotifier`
   writes it.
2. `puzzle_completions` (append-only) is the authority for **completion
   history** — stats, streaks, personal bests.
3. `solve_sessions` is the **resumable session cache** (Archive + resume),
   not historical truth.
4. `SolveRepositoryImpl._statusFromDb` and
   `SolveNotifier._deriveCompletionType` must remain inverses
   (locked by a round-trip test).

Alternatives rejected: notifier-as-authority (ephemeral, can't serve
Archive/Stats) and DB-as-authority (keystroke-latency regression).

## Consequences

- Divergence shrinks to five named, deliberate windows (documented in the
  design doc); six tightenings landed in PR #82.
- Any future completion-related field must pick its authority deliberately
  and document it.
