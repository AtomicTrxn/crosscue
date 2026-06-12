# Crosscue — Documentation Index

> **Status:** Living — update when adding, retiring, or re-homing a doc.

**Where docs live:** the **repo root** holds the evergreen project-wide set —
what Crosscue is and how to work on it (`README`, `PRODUCT`, `ARCHITECTURE`,
`MODELS`, `CONVENTIONS`, `DEPLOYMENT`, `CONTRIBUTING`, `SECURITY`). **`docs/`**
holds everything decision-shaped, dated, or operational: ADRs, design docs,
runbooks, QA checklists, policies, and reviews. Component-local READMEs
(`crosscue/backend/challenge_boards/`, `deeplinks/`) stay next to their code.

**Status convention:** every doc under `docs/` carries a status line —
**Living** (kept current; edit in place), **Snapshot (date)** (point-in-time;
never edited — corrections land in living docs), or **Historical** (plan of
record for shipped/superseded work).

## Product & policy

- [Privacy Policy](privacy.md) — **source of truth** for the published
  `privacy.html` filed with both stores (regeneration rule: DEPLOYMENT.md
  store checklists)
- [Product vision & principles](../PRODUCT.md) — why the app exists, the
  online-feature rule, roadmap themes, non-goals
- [Security policy](../SECURITY.md) — vulnerability disclosure

## Architecture (`docs/architecture/`)

- [Decisions (ADRs)](architecture/decisions/README.md) — one file per
  decision; the index lists all sixteen
- [Compatibility matrix](architecture/compatibility.md) — the five versioned
  contracts, support windows, Crosshare dependency policy *(Living)*
- [Threat model](architecture/threat-model.md) — trust boundaries, defended
  threats, accepted risks *(Living)*
- [Completion data authority](architecture/completion-authority.md) — who
  owns live vs. historical solve state *(Living; ADR-0008)*
- [Sync design](architecture/sync-design.md) — orchestrator/adapter/transport
  layers, merge rules, wire format *(Living; ADR-0009)*
- [Rebus entry](architecture/rebus-entry.md) — implementation plan
  *(Historical — shipped; ADR-0010)*
- [iOS App Intents](architecture/ios-app-intents.md) — Shortcuts/Siri/
  Spotlight runbook *(Living)*
- [iOS widget setup](architecture/ios-widget-setup.md) — WidgetKit one-time
  setup + payload schema *(Living)*
- [iCloud sync setup](architecture/sync-icloud-setup.md) — Apple-side
  one-time setup + verification *(Living)*
- [Google Drive sync setup](architecture/sync-googledrive-setup.md) — OAuth
  client setup *(Living)*

## QA (`docs/qa/`)

- [iOS release checklist](qa/ios-release-checklist.md) *(Living)*
- [Android release checklist](qa/android-release-checklist.md) *(Living)*

## Reviews & plans (point-in-time)

- [Design & architecture review](design-review-2026-06-11.md) *(Snapshot
  2026-06-11)* — planning-level review that produced PRODUCT.md, the ADR
  system, compatibility.md, and the threat model
- [Code review](code-review-2026-06-10.md) *(Living tracker until findings
  close)* — style/security/cloud findings with resolution status
- [App analysis](app-analysis-2026-06-07.md) *(Snapshot 2026-06-07)* — gap
  analysis: issues, findings F1–F7, parity P1–P4
- [Challenge Boards #159 breakdown](challenge-boards-159-breakdown.md)
  *(Living tracker — flips Historical when #159 closes)*
- `bug-evidence/` — screenshots referenced by issues

## Component docs (live with their code)

- [Challenge Boards Worker](../crosscue/backend/challenge_boards/README.md) —
  Cloudflare backend setup; [API contract](../crosscue/backend/challenge_boards/API.md)
- [Invite deep links](../deeplinks/README.md) — AASA/assetlinks hosting + QA
  matrix
