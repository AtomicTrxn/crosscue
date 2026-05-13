# Crosscue Roadmap

This keeps the durable follow-up trail from `CODE_REVIEW.md` outside the chat
history. Move items here only when they are still worth tracking after the
current cleanup pass.

## Backlog

- Continue revamping `onboarding_screen.dart` when that flow gets broader
  product/design attention.
- Consider moving parser tests fully under a mirrored `test/features/...`
  structure if more import parser coverage is added.

## Recently closed from the review pass

- Removed duplicate annotations and hot-path RegExp allocations.
- Centralized archive status presentation and shared Home/Archive puzzle rows.
- Moved solve-side effects out of `build` and switched archive/home data to
  reactive Drift streams.
- Split solve screen widgets and moved grid mutation helpers into domain code.
- Finished the theme-token cleanup for the reviewed screens.
- Replaced production `print` calls with app logging/reporting.
- Made route usage guardable with a test instead of relying on convention only.
- Split `crossword_grid.dart` into layout, input handling, and cell-effect
  animation parts.
