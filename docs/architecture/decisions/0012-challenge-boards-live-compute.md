# ADR-0012 — Challenge Boards v1: live-compute lifetime + bounded retention

**Status:** Accepted (locked) · **Date:** 2026-06-09 (#159)
**Plan of record:** [`../../challenge-boards-159-breakdown.md`](../../challenge-boards-159-breakdown.md)

## Context

The original #159 design called for a weekly rollover pipeline
(`daily_results` / `player_board_stats` / `processed_lifetime_weeks` + a
Monday cron) to materialize lifetime standings.

## Decision

v1 computes weekly **and lifetime** leaderboards **live** from retained
`challenge_results` rows, and does **not** build the rollover pipeline.
Because results are the lifetime source under this model, `challenge_results`
rows are intentionally **never purged**; retention applies only to the
audit-only `board_events` table (14-day daily cron). The rollover acceptance
criteria on #159 are superseded.

## Consequences

- Far less moving machinery for v1-scale boards (≤20 players, one result per
  player per daily puzzle — compact rows).
- Revisit (new ADR) if per-puzzle result volume grows unexpectedly or a
  `player_board_stats` rollover is introduced — only then may results
  retention change.
- Leaderboard read cost grows with history; #241 already batched the
  aggregation across boards.
