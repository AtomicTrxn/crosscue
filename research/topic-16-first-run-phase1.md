# Research Topic #16 — Phase 1 First-Run & Import-Only Experience

Status: Resolved
Implementation Status: ✅ Implemented — import flow, persistent onboarding, local-source Settings placement, and neutral empty states shipped by Sprint 12
Owner: Codex

## Research Question

What should a new user see on first launch when Phase 1 has no enabled network puzzle sources, and how should file import become the primary path into solving?

## Decision To Unblock

The app shell, onboarding, empty states, and import flow need a coherent Phase 1 path before implementation. Earlier UX notes assumed a "Browse Sources" action, but source research now limits Phase 1 to local `.puz` / `.ipuz` import and explicitly licensed fixtures or feeds.

## Recommendation

Phase 1 should be **import-first**:

- First launch shows lightweight onboarding, then the Home tab in an empty state.
- The primary CTA is **Import puzzle**.
- A secondary **Try sample puzzle** action is allowed only if the app includes a rights-cleared bundled fixture.
- Do not show **Browse Sources**, **Today's puzzle**, or publisher source discovery until a legally cleared source exists.
- Keep the route structure from topic #13: `HomeScreen` remains the default tab, `/import` handles file import, and `/solve/:puzzleId` opens the puzzle after a successful import.

## Supporting Research

Topic #7 makes publisher scraping and caching unsafe for Universal, LA Times, Guardian, and aggregators without explicit permission. Topic #1 remains useful as technical endpoint research, but topic #7 blocks those sources as enabled Phase 1 content. Topic #10 defines useful empty-state and onboarding patterns, but its source-browsing copy needs a Phase 1 override. Topic #13 already includes `ImportScreen` as a full-page route and marks it as the Phase 1 primary CTA.

## First-Launch Flow

1. App opens.
2. Router checks `hasSeenOnboarding`.
3. If onboarding has not been completed, show `OnboardingScreen`.
4. Onboarding teaches only source-independent mechanics:
   - Tap a cell.
   - Switch across/down.
   - Enter and erase letters.
   - Use check/reveal tools.
   - Import files when ready.
5. User completes or skips onboarding.
6. Router replaces onboarding with Home.
7. If there are no imported or bundled puzzles, Home shows the import empty state.

Do not require a puzzle file during onboarding. The user should be able to skip and still understand the next action.

## Home Empty State

Use this as the Phase 1 replacement for any "Browse Sources" copy:

| State | Headline | Body | Primary Action | Secondary Action |
|-------|----------|------|----------------|------------------|
| No puzzles imported | No puzzles yet | Import a `.puz` or `.ipuz` file to start solving. | Import puzzle | Try sample puzzle, only if bundled |
| No active puzzle, archive has imports | Ready for another? | Pick a saved puzzle or import a new one. | Import puzzle | Open archive |
| Active puzzle exists | Continue solving | Resume your latest puzzle. | Continue | Import puzzle |
| Import completed | Puzzle imported | Ready when you are. | Start solving | View details |

Home can still carry the tab label `Today` if the product direction wants a daily ritual later, but the visible Phase 1 content should not imply an automatically delivered daily puzzle.

## Import Flow

1. User taps **Import puzzle** from Home, Archive, or Settings.
2. App opens the platform file picker for supported puzzle formats.
3. Supported extensions for Phase 1: `.puz` and `.ipuz`.
4. App copies the selected file into app-controlled storage before parsing.
5. Parser validates the file and returns either a normalized puzzle model or a typed import error.
6. On success:
   - Create or update a `puzzles` row with `source_id = local_import`.
   - Store parsed clues, cells, metadata, checksum, and attribution.
   - Create an empty progress row.
   - Navigate to `/solve/:puzzleId` or show a compact puzzle detail confirmation with **Start solving**.
7. On failure, show the import error bottom sheet and keep the user on `/import`.

Prefer direct navigation to Solve after import for the MVP. A detail confirmation can be added if imported metadata is unreliable enough that users need to confirm title/date/source first.

## Import Error States

| Error | User Message | Recovery |
|-------|--------------|----------|
| Unsupported extension | Crosscue can import `.puz` and `.ipuz` files. | Choose another file |
| Parse failure | That puzzle file could not be read. It may use an unsupported format. | Choose another file; Report issue |
| Missing required data | This puzzle is missing clues, grid data, or a solution. | Choose another file |
| Duplicate import | This puzzle is already in your archive. | **Open existing puzzle** → navigate to `/solve/:existingPuzzleId` if in-progress, or to the archive entry if completed; **Choose another file** → dismiss sheet and return to ImportScreen |
| File too large | That file is larger than Crosscue can import. | Choose another file |
| Encrypted/protected puzzle | This puzzle uses protection Crosscue does not support yet. | Choose another file |

Error copy should avoid blaming the user or exposing parser internals. Developer details can be attached to an explicit bug report only after user review.

## Sample Puzzle Policy

A bundled sample puzzle is useful for onboarding and app-store screenshots, but it must be rights-cleared before it appears in builds. Acceptable sample sources:

- A puzzle authored specifically for Crosscue by the developer/team.
- A constructor-contributed puzzle with written permission and attribution.
- A public-domain or permissively licensed puzzle whose license allows app bundling.

Do not bundle downloaded publisher puzzles as samples.

## Legal & Privacy Notes

- Local import is user-provided content. The app should not imply it grants rights to download or redistribute publisher puzzles.
- Add small import-screen copy: "Import puzzle files you have permission to use."
- Imported files, parsed puzzle content, guesses, and solve history stay on device in Phase 1.
- Do not upload puzzle files or puzzle content in crash reports, feedback, analytics, or support emails.
- Preserve title, author, publisher, copyright, and notes metadata when present.

## Data Model Implications

Topic #2 already supports this shape:

- `sources` needs a built-in `local_import` pseudo-source.
- Local imports should use a checksum-based puzzle ID when no stable source ID exists.
- `puzzles` should preserve original metadata and import timestamps.
- Duplicate detection should compare checksum first, then fallback to title/date/author only as a weak hint.
- Import error details do not need permanent storage unless the user explicitly files feedback.

## Route & Screen Implications

Topic #13 remains valid with these Phase 1 clarifications:

- `HomeScreen` owns the import-first empty state.
- `ImportScreen` is the primary route for first-run action.
- `SolveScreen` is opened immediately after successful import.
- `ArchiveScreen` shows imported puzzles and completed solves.
- `StatsScreen` starts empty and points to import or continue depending on puzzle state.
- `SettingsScreen` includes "Import puzzle" and "Help / Tutorial"; no source-management UI is visible in Phase 1 unless a licensed source is enabled.

## Onboarding Adjustments

Topic #10's interactive onboarding should be kept, but source-dependent steps should be removed for Phase 1:

- Replace "Solve today's puzzle" with "Import a puzzle".
- Replace "Browse sources" with "Choose a `.puz` or `.ipuz` file".
- Tutorial replay can use a bundled sample puzzle only if the sample puzzle is rights-cleared.
- If no sample exists, tutorial replay should be text-light and mechanics-only, or require the user to open an imported puzzle first.

## Acceptance Criteria

- A fresh install has a valid path from launch to solving without network sources.
- No Phase 1 UI promises Browse Sources, Today's Puzzle, publisher feeds, or automatic downloads.
- Import is reachable from Home, Archive empty state, and Settings.
- Successful import creates a local puzzle and opens a solve path.
- Import failures are recoverable and understandable.
- Imported puzzle content is not sent to crash, feedback, analytics, or notification systems.
- The app remains useful offline after a puzzle is imported.

## Implementation Checklist

1. Seed `local_import` source during database initialization.
2. Add `ImportScreen` with file picker integration for `.puz` and `.ipuz`.
3. Define typed parser/import errors in the parser spec from topic #14.
4. Add `ImportPuzzleUseCase` that copies, parses, deduplicates, persists, and returns `puzzleId`.
5. Build Home empty states around `PuzzleLibraryState`.
6. Update onboarding copy and tutorial steps to avoid network-source assumptions.
7. Add import error bottom sheet from topic #13.
8. Add widget tests for first launch, empty Home, import success navigation, and import failure recovery.
9. Add integration tests with one valid `.puz`, one valid `.ipuz`, one duplicate, and one malformed file.

## Open Risks

- A bundled sample puzzle needs explicit rights clearance before use.
- Future licensed feeds will need a source-management UX pass; do not expose placeholder source browsing in Phase 1.
