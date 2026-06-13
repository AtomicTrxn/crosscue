# ADR-0016 — Mixed-version sync compatibility policy

**Status:** Accepted · **Date:** 2026-06-11 — the rule-3 behavior
(stop-pushing + update notice) shipped via #258; schema bumps are now
permitted under the rules below

## Context

`SyncBlob.decode()` returns null for blobs whose envelope `schemaVersion`
exceeds `currentSchemaVersion`; callers treat that as "skip this blob." That
is a safe *read* rule, but there is no *write/upgrade* rule. **As built
today**, a device on an older app version silently skips newer-schema blobs
while continuing to push its own older-schema blobs — so two devices on
either side of a schema bump can fork last-writer-wins namespaces (sessions,
settings) without anyone noticing.

## Decision

1. **Schema bumps are rare and deliberate.** Additive payload fields (which
   old readers ignore) are always preferred; bumping `currentSchemaVersion`
   is reserved for changes old readers would *misinterpret*, and is treated
   as a per-namespace flag day.
2. **Old data stays readable forever.** A new app version must read every
   prior blob schema; there is no "minimum readable schema".
3. **On observing a newer-schema blob**, a device must:
   - surface a persistent, non-blocking "Update Crosscue to keep syncing"
     state on the sync settings/status surface, and
   - **stop pushing to that namespace** (local use continues normally) —
     preventing the silent LWW fork. Pulling of still-readable namespaces
     continues.
4. **Release sequencing:** a schema-bumping app release notes the flag-day
   behavior in its release notes, and bumps are never combined with other
   risky sync changes.

## Consequences

- Mixed-version households degrade *visibly and recoverably* (update the lag
  device) instead of forking silently — satisfying support-window statement
  #3 in [`../compatibility.md`](../compatibility.md).
- Implemented (#258): per-namespace push suspension persisted in
  `app_settings` (`sync_upgrade_required_v1`, sync-excluded — the record is
  device-local by definition), `SyncIdle.upgradeRequired` drives a
  persistent "Update Crosscue to keep syncing" status line, and the guard
  self-clears once `currentSchemaVersion` reaches the observed version.
- Covered by `test/core/sync/sync_upgrade_guard_test.dart`: suspension +
  selective pushing, restart persistence, auto-clear after update, and
  malformed-bytes-don't-suspend.
