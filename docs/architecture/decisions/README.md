# Architecture Decision Records

> **Status:** Living index.

One file per decision, numbered in rough chronological order of the decision
(not the writing). **Rule:** any change significant enough that it would once
have added a bullet to `ARCHITECTURE.md` → "Recent Architectural Decisions"
writes an ADR here instead; `ARCHITECTURE.md` links to it with one line.

Format per ADR: **Status** (Proposed / Accepted / Superseded by ADR-NNNN),
**Date**, **Context** (the problem, in 1–3 sentences), **Decision**,
**Consequences**. Long design docs (e.g. `sync-design.md`) stay where they
are; the ADR is the durable decision record that points at them.

ADRs are immutable once Accepted except for status changes — a reversal is a
*new* ADR that supersedes the old one.

## Index

| ADR | Decision | Status |
|-----|----------|--------|
| [0001](0001-cell-progress-delete-then-insert.md) | Cell-progress autosave is delete-then-insert | Accepted |
| [0002](0002-clue-math-single-source.md) | All clue-cell math lives in `ClueProgressCalculator` | Accepted |
| [0003](0003-shared-settings-row-widgets.md) | Shared settings row widget library | Accepted |
| [0004](0004-plain-sealed-error-types.md) | Typed load errors are plain sealed classes | Accepted |
| [0005](0005-runtime-app-version.md) | App version is read at runtime, never hardcoded | Accepted |
| [0006](0006-crosshare-source-approval.md) | Crosshare Daily Mini approved as `openLicense` | Accepted |
| [0007](0007-settings-nested-routes.md) | Settings sub-pages are nested `GoRoute`s | Accepted |
| [0008](0008-completion-data-authority.md) | Completion data: hybrid model with named authorities | Accepted |
| [0009](0009-sync-architecture-and-rollout.md) | Sync: 3-layer orchestrator, per-namespace merge, opt-in rollout | Accepted |
| [0010](0010-rebus-entry-ux.md) | Rebus entry: NYT-aligned surfaces + first-letter acceptance | Accepted |
| [0011](0011-widget-background-refresh.md) | Widget background refresh is best-effort, not an observer | Accepted |
| [0012](0012-challenge-boards-live-compute.md) | Challenge Boards v1: live-compute lifetime + bounded retention | Accepted |
| [0013](0013-no-monetization.md) | No monetization; entitlement scaffolding removed | Accepted |
| [0014](0014-reminders-deferred.md) | Reminders deferred; scaffolding removed | Accepted |
| [0015](0015-platform-parity-policy.md) | Platform parity policy: parity-by-default | Proposed |
| [0016](0016-mixed-version-sync-policy.md) | Mixed-version sync compatibility policy | Proposed |
