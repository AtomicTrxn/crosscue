# Open Sprints — Crosscue

This file contains only planned, active, and deferred work so agents can inspect
what remains without loading the full completed sprint history. For shipped work,
read [COMPLETED_SPRINTS.md](COMPLETED_SPRINTS.md).

Status key: ✅ Done · 🔄 In Progress · ⬜ Planned · ⏸ Deferred

---


## Sprint 18 — `.ipuz` Parser Robustness & Metadata ✅

**Goal:** Keep Crosscue's `.ipuz` advantage over Crosshare, but make the parser more tolerant of common `.ipuz` variants and more complete in the metadata it preserves.

**Background:** Crosshare does not appear to support `.ipuz` import in its public converter. Crosscue already does, but the current parser is strict about clue-key casing, does not populate `publishDate`, and can collapse malformed JSON shapes into `ParseError.unknown`.

**Read before starting:** [ARCHITECTURE.md](ARCHITECTURE.md), [CONVENTIONS.md](CONVENTIONS.md), [MODELS.md](MODELS.md), [research/topic-14-puzzle-parser-spec.md](research/topic-14-puzzle-parser-spec.md)

### Scope

| Task | Status | Notes |
|------|--------|-------|
| **Publish date parsing** | ✅ | ISO `YYYY-MM-DD` and US `MM/DD/YYYY` parsed into `publishDate`; invalid dates silently become `null`. Both formats tested. |
| **Case-insensitive clue direction keys** | ✅ | `_findClueKey` searches map keys case-insensitively; `across`/`ACROSS`/`Across` all work. Tests for lower and upper variants. |
| **Defensive JSON shape validation** | ✅ | `dimensions`, `solution`, `solution` rows, and `clues` use `is` type checks returning `missingData`/`invalidFormat`; no unchecked casts. Tests for non-map dimensions, non-list solution rows, non-map clues. |
| **Block-cell variants** | ✅ | `'#'`, `null`, and numeric `0` in solution rows all map to black cells. `'.'` withheld (no fixture evidence; can be meaningful). |
| **Map-valued solution cells** | ✅ | Prefers `cell`/`answer`/`solution` string fields; numeric `value` ignored as numbering metadata. Tests for `{cell, value}`, `{cell: 'EST'}`, and `{answer}`. |
| **Clue object variants** | ✅ | Accepts `label` as number key and `hint` as text key. HTML tags and common entities stripped from all clue text via `_stripHtml`. |
| **Circle/style variants** | ✅ | `style.shape == 'circle'` and `circle: true` at cell level added alongside existing `shapebg`/`color` checks. |
| **Barred-boundary discovery hook** | ✅ | Rejection already in place from Sprint 16. Documented the future `SolutionCell` boundary model requirement in parser class doc and `_containsBarredGridData` comment. |
| **Metadata enrichment** | ✅ | `publishDate` wired; `publisher`/`editor` appended to notes when present. `title` HTML-stripped. |
| **Expanded fixture coverage** | ✅ | `_base3x3` shared builder; fixtures for lowercase/uppercase keys, HTML clues, ISO/US/bad dates, publisher+editor, numeric-0 black, map cells (`cell`, `answer`, numeric `value`), `style.shape`, `circle:true`, malformed dimensions/rows/clues. |

### Acceptance Criteria

| Check | Expected Result |
|-------|-----------------|
| `flutter test test/features/import/ipuz_parser_test.dart` | Passes with added robustness cases |
| Malformed row fixtures | Return structured parse errors, not crashes/unknown |
| Lowercase clue fixture | Imports across/down clues normally |
| Date fixture | Populates `PuzzleMetadata.publishDate` |
| Rebus map fixture | Uses real answer text, not numeric metadata |

**Key files:** `lib/features/import/data/parsers/ipuz_parser.dart`, `lib/core/domain/models/puzzle_metadata.dart`, `test/features/import/ipuz_parser_test.dart`

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
