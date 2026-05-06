# Crosscue Design Implementation Plan

This plan converts the files in `design/` into implementation work for the
Flutter app at `crosscue/`. The HTML files are high-fidelity visual
references, not production code to copy directly.

Status as of Sprint 13.5: Sprints 9-12 are complete. Sprint 13.5 cleanup is in
progress, and Sprints 13-14 remain the active design implementation backlog.

## Decisions

- Commit the `design/` folder as the source handoff for the redesign.
- Implement the redesign in phases, starting with theme/tokens and then the
  solve experience.
- Add a custom in-app QWERTY keyboard for solving.
- Keep the primary navigation focused on local/offline solving. Downloader and
  import management belong in Settings, not as the main Home action.
- Do not use copyrighted publisher names such as LA Times, Guardian, Universal,
  or NYT in production examples. Use neutral/local examples unless a source is
  legally cleared.
- Use `design/crosscue-icon.svg` as the app icon source.
- Keep Dynamic Color where it helps Material integration, but keep crossword
  grid, clue, keyboard, correctness, and reveal colors stable for readability.
- Preserve and verify dark mode during each phase.

## Source Files

| File | Role |
|------|------|
| `design/README.md` | Design handoff and screen specs |
| `design/Crosscue Design Review.html` | High-fidelity screen mockups |
| `design/Crosscue App Icon.html` | Icon concept reference |
| `design/crosscue-icon.svg` | Selected final icon artwork |
| `design/design_tokens.dart` | Token source for colors, type, spacing |
| `design/app_theme.dart` | Theme handoff reference |
| `design/crossword_theme.dart` | Crossword-specific theme handoff reference |

## Implementation Order

### Sprint 9 — Design Foundation

Goal: make the app's global visual language match the design handoff without
changing core workflows.

Status: Complete.

- Add `design_tokens.dart` to `lib/core/theme/`.
- Adapt `AppTheme` to the new typography, app bar, nav bar, button, chip,
  divider, and list tile styling.
- Expand `CrosswordTheme` with the extra grid, clue bar, clue panel, keyboard,
  and state tokens from the handoff.
- Keep dynamic Material You for app chrome while preserving fixed crossword
  colors for readability.
- Verify light and dark mode.

### Sprint 10 — Solve Redesign

Goal: make the solve screen match the high-fidelity references.

- Refactor `SolveScreen` to use the compact 48dp app bar.
- Add a tappable `ClueBar` above the grid that toggles across/down.
- Make the grid full-width with cell size based on puzzle width.
- Update `CrosswordGridPainter` to use the expanded theme tokens, outer border,
  cell border, active word, cross word, checked, and revealed colors.
- Replace the two-line clue summary with the two-column clue panel.
- Add a custom QWERTY keyboard with delete and check-word keys.
- Preserve physical keyboard support and haptics.
- Verify 15x15 and mini layouts in light and dark mode.

### Sprint 11 — Home, Archive, Stats

Goal: bring the main tab surfaces into the flat list-based design language.

- Redesign Home around local/offline use instead of a publisher "Today" feed.
  Use a local "Current puzzle" or "Continue" section based on imported/opened
  puzzles.
- Keep import as a local action, but move downloader/source management to
  Settings.
- Redesign Archive rows, filter chips, sort bar, and status icons.
- Redesign Stats as flat sections with mono time values and no cards.
- Use neutral sample/empty-state text only.

### Sprint 12 — Settings, Import, Onboarding

Goal: align secondary flows with the new design and make Settings the home for
import/source management.

Status: Complete.

- Redesign Settings rows, theme controls, haptics toggle, and destructive
  actions.
- Add Settings entry points for local import and future source/downloader
  management.
- Keep future source/downloader controls disabled or absent until a source has
  `openLicense` or `explicitPermission`.
- Restyle Import and Onboarding screens using the shared tokens.
- Preserve accessibility labels and confirmation dialogs.

### Sprint 13 — Icon, Splash, Visual QA

Goal: finish polish and visual verification.

- Convert `design/crosscue-icon.svg` into Android launcher icon assets.
- Update splash background to `#0A2A6E`.
- Capture visual QA screenshots for Home, Solve 15x15, Solve mini, Archive,
  Stats, Settings, Onboarding, Import, and completion sheet.
- Verify light and dark mode.
- Run `flutter analyze`, `flutter test`, and a debug APK build.

## Acceptance Criteria

- All redesigned screens use the token system rather than ad hoc colors.
- Crossword readability does not depend on Android Dynamic Color.
- The custom keyboard supports letter entry, delete, and check-word behavior.
- Physical keyboard input still works.
- No production UI uses uncleared publisher names as built-in examples.
- Downloader/source management is discoverable from Settings, not Home.
- `flutter analyze` reports 0 issues.
- `flutter test` passes.
