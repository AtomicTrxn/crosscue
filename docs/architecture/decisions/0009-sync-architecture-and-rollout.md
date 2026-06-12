# ADR-0009 — Sync: three-layer orchestrator, per-namespace merge, opt-in rollout

**Status:** Accepted · **Date:** 2026-05 → 2026-06 (G5, #9; transports #142/#145/#157)
**Full design doc:** [`../sync-design.md`](../sync-design.md)

## Context

Cross-device sync of the library, sessions, completion history, and a
settings allowlist — without a Crosscue server, preserving the privacy
identity.

## Decision

- **Three layers:** `SyncOrchestrator` (triggers/status) →
  `NamespaceSyncAdapter` per namespace (entity shape + merge rule) →
  `SyncTransport` (the only platform-aware piece: iCloud Documents on iOS,
  Drive AppData on Android, `NoOp`/`Fake` elsewhere).
- **Merge semantics chosen per data meaning:** content-addressable union
  (puzzles), client-UUID set union (completions), LWW + best-progress
  override (sessions), LWW per key (settings).
- **Wire format:** one blob per entity + a manifest; envelope carries
  `schemaVersion` with forward-compat skip (see ADR-0016 for the
  mixed-version policy).
- **Rollout:** ships **opt-in, off by default — no default-on flip**;
  enabled from onboarding or Settings. No background sync in v1
  (app-resume + debounced post-write triggers only).

## Consequences

- No server, no accounts — the user's own cloud is the boundary
  (threat-model.md).
- Cross-platform (iOS↔Android) migration is explicitly *not* sync's job;
  the privacy-screen export/import is the bridge.
- Android remains inert until the Google OAuth clients exist
  (`sync-googledrive-setup.md`).
