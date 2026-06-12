# ADR-0007 — Settings sub-pages are nested `GoRoute`s

**Status:** Accepted · **Date:** 2026-05 (v1.1)

## Context

Settings grew sub-pages (sources, Crosshare config, privacy, later sync) that
should preserve the shell's tab state and back-stack semantics.

## Decision

Sub-pages live as nested `GoRoute` entries inside the Settings shell branch
(`/settings/sources`, `/settings/sources/crosshare`, `/settings/privacy`,
`/settings/sync`). Navigation always uses absolute `Routes` constants.

## Consequences

- Back behaves correctly within the tab; deep paths are addressable.
- New settings surfaces follow the same nesting; no full-page settings routes.
