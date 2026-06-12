# ADR-0005 — App version is read at runtime, never hardcoded

**Status:** Accepted · **Date:** 2026 (Sprint 5)

## Context

Hardcoded version strings in the About/settings UI go stale the release after
they're written.

## Decision

`appVersionProvider` (`core_providers.dart`) reads the version via
`PackageInfo.fromPlatform()`. No UI string ever hardcodes a version.

## Consequences

- `pubspec.yaml` is the single version source; release bumps need no UI edits.
