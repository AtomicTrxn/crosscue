# ADR-0014 — Reminders deferred; scaffolding removed

**Status:** Accepted · **Date:** 2026-06 (#211; flagged as F3 in the
2026-06-07 analysis)

## Context

Daily/streak reminder settings keys (`daily_reminder_*`, `streak_reminder_*`,
`notifications_*`) and sync exclusions were scaffolded with no notification
plugin, scheduler, or UI on either platform — dead surface implying a shipped
feature.

## Decision

The scaffolding was **removed** in #211. Reminders are **deferred**, not
rejected: they fit the retention theme (`PRODUCT.md`) and a streak-based
daily-puzzle app is a natural fit for them.

If built, the shape is constrained in advance:

- **Local-only** (`flutter_local_notifications`-class plugin, zoned
  scheduling) — no push infrastructure, no server, consistent with the
  online-feature rule.
- Settings keys return with the feature, with deliberate sync scoping
  (reminder *times* are arguably per-device; decide via the per-key
  allowlist when implementing).
- Privacy policy + both store data-safety forms re-reviewed before shipping
  (expected outcome "no change" — on-device notifications collect nothing —
  but the re-review is mandatory per DEPLOYMENT.md).

## Consequences

- No reminder code or keys exist today; docs referencing them describe
  history, not the present.
- Building reminders starts with an epic issue referencing this ADR, not
  with code.
