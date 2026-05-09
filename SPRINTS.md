# Open Sprints — Crosscue

This file contains only planned, active, and deferred work so agents can inspect
what remains without loading the full completed sprint history. For shipped work,
read [COMPLETED_SPRINTS.md](COMPLETED_SPRINTS.md).

Status key: ✅ Done · 🔄 In Progress · ⬜ Planned · ⏸ Deferred

---



---

## Deferred / Post-MVP

| Item | Notes |
|------|-------|
| Pencil mode | `EntryMode.pencil` enum already defined; `cell_progress.is_pencil` column exists |
| Rebus entry (multi-letter cells) | Planned in Sprint 16; `EntryMode.rebus` defined and rebus parsed from `.puz`, but not yet editable |
| Sync adapter (iCloud / Drive) | `SyncAdapter` interface + `NoOpSyncAdapter` stub in `core/sync/` |
| Subscription / entitlement | `EntitlementService` interface + `FreeEntitlementService` stub in `core/entitlement/` |
| iOS support | Phase 2; Android is Phase 1 target |
| Automated puzzle downloaders | Only for `LicenseStatus.openLicense` or `explicitPermission` sources; management lives in Settings |
