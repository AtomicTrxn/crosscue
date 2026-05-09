# Open Sprints — Crosscue

This file contains only planned, active, and deferred work so agents can inspect
what remains without loading the full completed sprint history. For shipped work,
read [COMPLETED_SPRINTS.md](COMPLETED_SPRINTS.md).

Status key: ✅ Done · 🔄 In Progress · ⬜ Planned · ⏸ Deferred

---

## Sprint 17 — `.puz` Parser Compatibility Hardening ✅

**Goal:** Make Crosscue's `.puz` importer compatible with more real-world Across Lite files and Crosshare-exported files, while keeping local imports safe and deterministic.

**Background:** Crosshare only imports/exports `.puz` in its public upload path, but its parser has useful battle-tested behavior around encoding, dimensions, rebus tables, hidden cells, and fixture coverage. Crosscue already supports `.puz` import, but several edge cases can currently import incorrectly or lose metadata/styling.

**Read before starting:** [ARCHITECTURE.md](ARCHITECTURE.md), [CONVENTIONS.md](CONVENTIONS.md), [research/topic-14-puzzle-parser-spec.md](research/topic-14-puzzle-parser-spec.md)

### Scope

| Task | Status | Notes |
|------|--------|-------|
| **Rebus RTBL/GRBS compatibility** | ✅ | `rebusTable[slot] ?? rebusTable[slot - 1]` fallback; both standard and Crosshare-style 0-based keys tested. |
| **GEXT circle flag compatibility** | ✅ | Accepts both `0x10` (standard) and `0x80` (Crosshare); both bit values covered by tests. |
| **String decoding for newer `.puz` files** | ✅ | Try UTF-8 first (`allowMalformed: false`), fall back to Latin-1 on `FormatException`. Unicode title/author tested (`Mañana` fixture). |
| **Dimension guardrails** | ✅ | 2×2 min, 25×25 max. Zero → `missingData`; out-of-range → `unsupportedFormat`. Min/max boundary tests added. |
| **Hidden-cell handling** | ✅ | Solution byte `0x3A` (`:`) → `ParseError.unsupportedFormat`. Deferred to future domain-model work. |
| **Scramble flag review** | ✅ | Only bit `0x0004` locks the solution; other nonzero bits tolerated. Tests for both `0x0004` rejection and `0x0001` pass-through. |
| **Canonical checksum includes rebus expansion** | ✅ | ID hashes resolved cell solutions (including rebus text) via `base64(utf8(resolvedSolution))`; plain vs. rebus IDs are distinct; IDs stable for unchanged ASCII puzzles. |
| **Note cleanup policy** | ✅ | Decided to preserve constructor notes verbatim — no boilerplate stripping. `notes` field passed through as-is. |
| **Real-world fixture expansion** | ✅ | Added `crosshareRebus3x3`, `circlesGext80_3x3`, `utf8Title3x3`, `hiddenCell3x3`, `nonScrambleFlag` to `PuzFixtureBuilder`; all fixtures used in new test groups. |

### Acceptance Criteria

| Check | Expected Result |
|-------|-----------------|
| `flutter test test/features/import/puz_parser_test.dart` | Passes with added compatibility cases |
| Existing parser tests | Continue passing unless an intentional checksum/ID change is documented |
| Crosshare-style rebus fixture | Imports multi-character solution correctly |
| Crosshare-style circle fixture | Preserves circled cells |
| Hidden-cell fixture | Returns unsupported instead of silently importing `:` as an answer |

**Key files:** `lib/features/import/data/parsers/puz_parser.dart`, `lib/core/domain/models/solution_cell.dart`, `test/features/import/puz_parser_test.dart`, `test/helpers/puz_fixture_builder.dart`

---

## Sprint 18 — `.ipuz` Parser Robustness & Metadata ⬜

**Goal:** Keep Crosscue's `.ipuz` advantage over Crosshare, but make the parser more tolerant of common `.ipuz` variants and more complete in the metadata it preserves.

**Background:** Crosshare does not appear to support `.ipuz` import in its public converter. Crosscue already does, but the current parser is strict about clue-key casing, does not populate `publishDate`, and can collapse malformed JSON shapes into `ParseError.unknown`.

**Read before starting:** [ARCHITECTURE.md](ARCHITECTURE.md), [CONVENTIONS.md](CONVENTIONS.md), [MODELS.md](MODELS.md), [research/topic-14-puzzle-parser-spec.md](research/topic-14-puzzle-parser-spec.md)

### Scope

| Task | Status | Notes |
|------|--------|-------|
| **Publish date parsing** | ⬜ | Parse common `.ipuz` `date` values into `PuzzleMetadata.publishDate`: ISO `YYYY-MM-DD`, US `MM/DD/YYYY`, and compact variants only if they can be interpreted unambiguously. Keep invalid dates as `null` rather than failing import. Update the existing date test so it asserts the stored date, not only that parsing succeeds. |
| **Case-insensitive clue direction keys** | ⬜ | Accept `Across`/`Down`, `across`/`down`, and other simple case variants. Keep output clues normalized to `Direction.across` / `Direction.down`. Add tests where only lowercase keys are present. |
| **Defensive JSON shape validation** | ⬜ | Replace unchecked casts for `solution` rows, `puzzle` rows, `dimensions`, and `clues` with type checks that return `ParseError.missingData` or `ParseError.invalidFormat`. The parser should never return `ParseError.unknown` for ordinary malformed `.ipuz` structure. |
| **Block-cell variants** | ⬜ | Support common black-cell representations in solution/puzzle grids: `'#'`, `null`, and numeric `0` where appropriate. Review whether `'.'` should be accepted as a block for compatibility; add only if fixture-backed because `'.'` can be meaningful in some JSON contexts. |
| **Map-valued solution cells** | ⬜ | Current logic uses `val['cell'] ?? val['value']`; this can turn numeric `value` fields into answer text. Prefer string-like answer fields (`cell`, `answer`, `solution`) and treat numeric `value` as numbering/style metadata unless paired with a real answer string. Add rebus tests for map cells with both `value` and `cell`. |
| **Clue object variants** | ⬜ | Extend clue parsing to accept common fields such as `label`, `cells`, or stringified `number` when present. Continue ignoring unsupported rich metadata, but never crash. Preserve clue text after stripping simple HTML tags/entities where safe. |
| **Circle/style variants** | ⬜ | Crosscue currently recognizes `style.shapebg == 'circle'` or `style.color == 'circle'`. Add support for common style keys such as `style.shape == 'circle'` or direct `circle: true` if observed in fixtures. Keep unsupported style data ignored. |
| **Barred-boundary discovery hook** | ⬜ | Sprint 16 may introduce barred-grid boundaries. During `.ipuz` hardening, inspect known keys for cell-side bars and document the mapping needed for `SolutionCell` or a future boundary model. If the domain model is not ready, reject barred `.ipuz` puzzles as unsupported instead of importing wrong word lengths. `.jpz` remains out of scope until a parser exists. |
| **Metadata enrichment** | ⬜ | Preserve simple metadata already supported by `PuzzleMetadata`: `title`, `author`, `copyright`, `difficulty`, `notes`, and `publishDate`. Consider mapping `publisher`/`editor` into notes only if it improves display without polluting constructor notes. |
| **Expanded fixture coverage** | ⬜ | Add synthetic `.ipuz` fixtures for lowercase clues, date variants, numeric blocks, malformed rows, map rebus cells, extra clue fields, circle style variants, and invalid-but-noncrashing inputs. |

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
