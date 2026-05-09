# Open Sprints — Crosscue

This file contains only planned, active, and deferred work so agents can inspect
what remains without loading the full completed sprint history. For shipped work,
read [COMPLETED_SPRINTS.md](COMPLETED_SPRINTS.md).

Status key: ✅ Done · 🔄 In Progress · ⬜ Planned · ⏸ Deferred

---

## Sprint 17 — `.puz` Parser Compatibility Hardening ⬜

**Goal:** Make Crosscue's `.puz` importer compatible with more real-world Across Lite files and Crosshare-exported files, while keeping local imports safe and deterministic.

**Background:** Crosshare only imports/exports `.puz` in its public upload path, but its parser has useful battle-tested behavior around encoding, dimensions, rebus tables, hidden cells, and fixture coverage. Crosscue already supports `.puz` import, but several edge cases can currently import incorrectly or lose metadata/styling.

**Read before starting:** [ARCHITECTURE.md](ARCHITECTURE.md), [CONVENTIONS.md](CONVENTIONS.md), [research/topic-14-puzzle-parser-spec.md](research/topic-14-puzzle-parser-spec.md)

### Scope

| Task | Status | Notes |
|------|--------|-------|
| **Rebus RTBL/GRBS compatibility** | ⬜ | Crosshare writes `GRBS` values as 1-based indexes and `RTBL` entries as 0-based keys, then imports with `slot - 1`. Crosscue currently looks up `rebusTable[slot]` only. Update `PuzParser` to resolve rebus text with a compatibility order like `rebusTable[slot] ?? rebusTable[slot - 1]`, falling back to the single solution byte only if no table value exists. Add parser tests for both `01:EST;`/slot `1` and Crosshare-style ` 0:EST;`/slot `1`. |
| **GEXT circle flag compatibility** | ⬜ | Crosscue currently checks only GEXT bit `0x10`; Crosshare reads/writes `0x80`. Accept both bits as circled during import so Crosshare-exported circles are preserved. Update stale comments in `SolutionCell` and parser docs so they describe compatibility rather than a single bit. Keep existing `0x10` tests and add `0x80` coverage. |
| **String decoding for newer `.puz` files** | ⬜ | Crosshare switches string decoding to UTF-8 for newer version data and otherwise uses ISO-8859-1. Crosscue always uses Latin-1. Add a small decoder helper for null-terminated strings: use the version field at `0x18` as the first signal, decode UTF-8 when indicated, and fall back to Latin-1 if decoding fails or the file is an older version. Cover Unicode title/author/clue text with tests. |
| **Dimension guardrails** | ⬜ | Crosscue only rejects zero width/height. Add app-supported bounds before allocating cells, for example min `2x2` and max `25x25` unless product direction chooses a different maximum. Return `ParseError.unsupportedFormat` for dimensions outside the supported app range and `ParseError.missingData` only for incomplete/truncated files. Add min/max tests. |
| **Hidden-cell handling** | ⬜ | Crosshare treats solution byte `:` as a hidden cell and maps it to a block/hidden marker. Crosscue would currently treat `:` as a literal solution. Until the domain model supports hidden cells, reject `.puz` files containing `:` with `ParseError.unsupportedFormat` rather than importing wrong answers. Document hidden-cell support as deferred if rejected. |
| **Scramble flag review** | ⬜ | Crosscue rejects any nonzero scrambled tag. Crosshare rejects when bit `0x0004` is set. Review the Across Lite spec and adjust only if nonzero values other than `0x0004` are valid non-scramble metadata. Add tests for scrambled rejection either way. |
| **Canonical checksum includes rebus expansion** | ⬜ | Crosscue's `.puz` duplicate ID/checksum currently hashes raw solution bytes, so puzzles differing only by rebus expansion can collide. Include the normalized parsed solution strings, including rebus text, in the canonical checksum. Preserve deterministic IDs for unchanged non-rebus fixtures or document the expected ID change in tests. |
| **Note cleanup policy** | ⬜ | Crosshare strips generated-by boilerplate like "created on/with ...". Decide whether Crosscue should preserve raw constructor notes or remove known generator boilerplate. If implemented, keep it conservative and fixture-backed so meaningful notes are not lost. |
| **Real-world fixture expansion** | ⬜ | Add non-licensed/synthetic fixtures that mimic Crosshare's corpus cases: version 1.2 notes, odd numbering, partially-filled player grid, Crosshare-style rebus, `0x80` circles, malformed extensions, and hidden-cell rejection. Keep fixtures generated or legally safe; do not commit publisher-owned puzzle content. |

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
