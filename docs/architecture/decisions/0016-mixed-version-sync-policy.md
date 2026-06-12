# ADR-0016 — Mixed-version sync compatibility policy

**Status:** Proposed (awaiting owner sign-off; implementation is a tracked
code task) · **Date:** 2026-06-11

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
- Code change required: today's behavior implements the skip but not the
  stop-pushing or the user-facing state. Until that lands, avoid bumping
  `currentSchemaVersion` at all.
- Property tests should cover: old-reader-ignores-additive-fields, and
  newer-blob-observed → namespace push suspended.
