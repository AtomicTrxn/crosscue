# ADR-0006 — Crosshare Daily Mini approved as `openLicense`

**Status:** Accepted · **Date:** 2026-05-10

## Context

The legal guardrail (`CONVENTIONS.md` → "Puzzle Sources — Legal Guardrail")
requires explicit, documented approval before any online source is enabled.
Crosshare hosts author-attributed, user-generated puzzles.

## Decision

Crosshare Daily Mini is approved as `openLicense` and registered through the
`SourceRegistry` guardrail. Each puzzle remains author-attributed and the app
links back to the source. Perpetual offline storage of downloaded puzzles was
accepted per the legal review recorded in the `CONVENTIONS.md` source table.

## Consequences

- The first (and so far only) networked puzzle source; daily auto-download
  and Challenge Boards eligibility both build on it.
- Operational risk: the download path is an HTML scraper and a single point
  of failure — see `compatibility.md` → "External dependency: Crosshare".
- Any future source must repeat this process and update the `CONVENTIONS.md`
  table with date, approver, rationale, and review reference.
