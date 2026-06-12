# ADR-0015 — Platform parity policy: parity required across all app targets

**Status:** Accepted · **Date:** 2026-06-11 (decided by owner; the original
draft proposed a weaker "parity-by-default with a lag window" — rejected in
favor of required parity)

## Context

iOS has accumulated user-visible features Android lacks: the WidgetKit
home/lock-screen widget (P1), App Intents / Shortcuts / Siri (P2), and a
branded share sheet (P3). Nothing stated whether iOS-first was deliberate, so
each gap read as an accident with no clock on closing it.

## Decision

**Platform parity is required.** All app targets — currently **iOS and
Android** — stay in parity:

1. A user-visible feature ships only when it works on **every app target**.
   No staggered releases, no "iOS-first with a parity issue filed."
2. When a feature uses a platform-specific surface (WidgetKit, App Intents,
   Live Activities, Material You, …), its closest equivalent on the other
   platform (Glance widget, App Shortcuts, …) ships **in the same release**.
   If no reasonable equivalent exists, the feature waits or is redesigned —
   it does not ship one-sided.
3. The bar is **functional parity**: platform-native polish on top of a
   function both platforms have (e.g., the branded iOS share preview vs.
   plain `share_plus` — P3) is acceptable, but the function itself must
   exist everywhere.
4. Implementation may differ per platform by design (iCloud vs. Google Drive
   sync backends) as long as the user-facing feature is equivalent.
5. New app targets (desktop, web, …) join the parity set only via a new ADR
   that supersedes this one; until then "all app targets" means iOS +
   Android.

## Consequences

- **P1 (Android home-screen widget)** and **P2 (Android App Shortcuts for
  the three intents)** are now policy violations, not optional polish —
  they are the standing parity debt to close, and no new feature may widen
  the gap. The WorkManager plumbing for P1 already runs on Android and
  currently pushes to nothing.
- Feature planning budgets both platforms from the start; "which platform
  first?" is no longer a question.
- Every feature release runs **both** QA checklists
  (`docs/qa/ios-release-checklist.md` and
  `docs/qa/android-release-checklist.md`).
