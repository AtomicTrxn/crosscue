# ADR-0015 — Platform parity policy: parity-by-default

**Status:** Proposed (awaiting owner sign-off) · **Date:** 2026-06-11

## Context

iOS has accumulated user-visible features Android lacks: the WidgetKit
home/lock-screen widget (P1), App Intents / Shortcuts / Siri (P2), and a
branded share sheet (P3). Nothing states whether iOS-first is deliberate, so
each gap reads as an accident and there is no clock on closing any of them.

## Decision

**Parity-by-default**, with a defined exception path:

1. A user-visible feature ships on **both platforms together** unless its
   surface is platform-specific (WidgetKit, App Intents, Live Activities,
   Material You, Quick Settings tiles, …).
2. When a platform-specific surface ships first, a **parity issue is filed at
   ship time** describing the closest equivalent (e.g., Glance widget, App
   Shortcuts) with a target of **≤ 2 minor releases** lag. Missing the target
   needs an explicit note on the issue, not silence.
3. **Cosmetic enrichments** (e.g., the branded iOS share preview vs. plain
   `share_plus`) are exempt from the clock but still tracked.
4. Features intentionally exclusive to one platform forever must be listed in
   `PRODUCT.md` non-goals (none exist today; sync *backends* differ by design
   but the sync feature itself has parity).

## Consequences

- P1 (Android Glance widget — the WorkManager plumbing already runs and
  pushes to nothing) and P2 (Android App Shortcuts for the same three
  intents) become scheduled debt with the policy clock started at this ADR's
  acceptance.
- "Which platform do we build for first?" becomes a checklist answer instead
  of a per-feature debate.
