# ADR-0013 — No monetization; entitlement scaffolding removed

**Status:** Accepted · **Date:** 2026-06 (#211; flagged as F4 in the
2026-06-07 analysis)

## Context

`lib/core/entitlement/` scaffolded a paid tier (`EntitlementService`,
`FreeEntitlementService`, a `licensed_daily_reminder_enabled` settings key)
with no billing integration and no decided direction. Two reviews flagged it
as dead surface implying an unshipped feature.

## Decision

Crosscue has **no monetization**. The entitlement abstraction and `licensed_*`
settings key were removed in #211. Everything the app does is free.

Constraints on any future revisit (which requires a new ADR superseding this
one): **never** ads, analytics, subscriptions, or gating of core solving —
those contradict the product identity (`PRODUCT.md`). The only option that
would be considered is a one-time, cosmetic-or-nothing "supporter" unlock.

## Consequences

- No entitlement checks anywhere in the codebase; features are not written
  "free-tier-aware".
- Store listings, privacy policy, and data-safety forms stay simple (no
  purchase data).
