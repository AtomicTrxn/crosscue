# Research Topic #10 — Design & UX Research

Status: Resolved
Implementation Status: 🔄 Partially Implemented — Material 3, design tokens, CrosswordTheme, haptics, completion feedback, onboarding, Settings, and Import styling shipped by Sprint 12; broader screen redesign and animation polish remain in Sprints 10–13/Post-MVP
Owner: Claude

## Research Question

What visual design and UX direction should guide typography, color, layout, micro-interactions, onboarding, loading/error states, motivation loops, branding, and Flutter package choices?

## Overview

This document covers visual design and UX research for the crossword app: typography, color system, layout patterns, micro-interactions, navigation, onboarding, and branding. All recommendations are Flutter/Material 3 specific and validated against current (2026) standards from the NYT, Wordle, Duolingo, and Material Design ecosystems.

---

## Typography

### Design Principles

- Use **Material 3's built-in type scale** (Roboto) as the foundation — no extra packages needed for most cases
- Limit to **two font families maximum**: platform/default Roboto for all UI, bundled Roboto Mono for the timer only
- Keep the app offline-first: do not rely on runtime font fetching in production
- Never go below 14px for primary content; clue text at 14–16px minimum
- Always use **tabular (fixed-width) numbers** for the timer so digits don't shift width as the clock ticks

### Grid Cell Letters

| Property | Value | Rationale |
|----------|-------|-----------|
| Font | Roboto | Material 3 default; legible at small sizes |
| Weight | Regular (w400) for normal cells; Bold (w600) for pencil/check states | Distinction between in-progress and verified |
| Size | 24–32px (scales with cell size) | Readable on 44dp minimum touch target |
| Case | Uppercase always | Traditional crossword convention; faster visual scanning |
| Alignment | Center horizontal and vertical | Standard grid presentation |

> **Avoid monospaced fonts for grid letters.** Proportional fonts look more natural; monospaced creates excessive whitespace around narrow letters (I, l, t). The NYT uses Franklin Gothic — Roboto is its closest freely-available equivalent.

### Clue Numbers Inside Cells

| Property | Value |
|----------|-------|
| Font | Roboto |
| Weight | Medium (w500) |
| Size | 8–10px (Material: `labelSmall`) |
| Color | 60% opacity of cell text color |
| Position | Top-left corner, 2dp padding |

### Clue Panel Text

| Context | Style | Size | Weight |
|---------|-------|------|--------|
| Active clue (ClueBar) | `titleSmall` | 14px | Medium |
| Clue list numbers | `labelMedium` | 12px | Medium |
| Clue list body | `bodyMedium` | 14px | Regular |
| Section headers (ACROSS / DOWN) | `labelLarge` | 14px | Medium, uppercase |

Line height: 1.4–1.5× font size for clue lists. Characters per line: 45–75 (avoid longer wrapping lines in clue panel).

### Timer

| Property | Value |
|----------|-------|
| Font | Roboto Mono |
| Size | 16px |
| Weight | Regular |
| Alignment | Right-aligned in app bar |
| Format | `M:SS` under 1 hour (e.g. `4:23`, `59:07`); `H:MM:SS` at 1 hour or above (e.g. `1:02:45`) |

Using Roboto Mono ensures digits never shift width. The format intentionally omits a leading zero on minutes (`4:23` not `04:23`) to keep the display compact. The timer container must accommodate 7 characters (`H:MM:SS`) to prevent layout shift on long solves.

### App Bar & Navigation

| Element | Material 3 Token | Size | Weight |
|---------|-----------------|------|--------|
| Screen title | `titleLarge` | 22px | Regular |
| Bottom nav labels | `labelMedium` | 12px | Medium |
| Toolbar action labels | `labelLarge` | 14px | Medium |
| Stats/badges | `labelSmall` | 11px | Medium |

### Flutter Implementation

```dart
ThemeData(
  useMaterial3: true,
  // Use the platform/default Material text theme for Roboto.
  // Timer widget specifically:
  // Text(timerString, style: TextStyle(fontFamily: 'RobotoMono', fontSize: 16))
)
```

Bundle the Roboto Mono weights used by the timer in app assets and register them in `pubspec.yaml`. Only add `google_fonts` if the release build disables HTTP fetching or ships matching font assets locally.

### Accessibility — Text Scaling

- Use `TextScaler` (not deprecated `textScaleFactor`) to respect device font size settings
- Clamp grid cell text to prevent overflow: `MediaQuery.withClampedTextScaling(minScaleFactor: 0.8, maxScaleFactor: 1.2)`
- Clue panel text should scale freely with system settings — users who need large text need it there
- Test at 125% and 175% system text scale

---

## Color System

### Design Philosophy

- Use **Material You dynamic color** on Android 12+ (generates palette from user's wallpaper)
- Provide a **fixed fallback palette** seeded from `#2196F3` (Material Blue) for older Android and all iOS
- Grid interaction colors (active cell, word highlight, correct/incorrect) are **crossword-specific tokens** that live outside the standard Material palette — define them in a `CrosswordColors` extension
- **Dark mode is not a simple inversion** — grid blacks become dark gray, highlights brighten, no pure white text

### Seed Color & Material 3 Tokens

```dart
const Color seedColor = Color(0xFF2196F3); // Material Blue

ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light, // or Brightness.dark
)
```

For Android 12+, use the `dynamic_color` package to read the system palette and fall back to the seed if unavailable.

### Light Mode Palette

#### Standard Material tokens (auto-generated from seed)
| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#1565C0` | Buttons, active states, app bar accent |
| `primaryContainer` | `#BBDEFB` | Word highlight background |
| `secondary` | `#FDD835` | Active cell highlight |
| `surface` | `#FAFAFA` | Screen backgrounds |
| `onSurface` | `#1F1F1F` | Body text |
| `error` | `#EF5350` | Incorrect cell state |

#### Crossword-specific tokens (custom extension)
| Token | Hex | Usage |
|-------|-----|-------|
| `gridBlack` | `#000000` | Filled/blocked squares |
| `gridEmpty` | `#FFFFFF` | Empty cell background |
| `gridBorder` | `#E0E0E0` | Cell borders (1–2px) |
| `gridOuterBorder` | `#000000` | Thick outer grid border |
| `cellActive` | `#FDD835` | Focused cell (current cursor position) |
| `wordHighlight` | `#BBDEFB` | All cells in the active word |
| `crossHighlight` | `#E3F2FD` | Cells in the crossing (perpendicular) word |
| `stateCorrect` | `#4CAF50` | Verified correct entry |
| `stateIncorrect` | `#EF5350` | Verified incorrect entry |
| `stateRevealed` | `#FFF9C4` | Revealed via hint (pale yellow — distinct from `cellActive`) |
| `cellText` | `#1F1F1F` | User-entered letters |
| `cellNumber` | `#424242` | Clue number labels in cells |

### Dark Mode Palette

> Key rule: **never use pure black (#000000) for blocked squares in dark mode** — it causes harsh contrast and eye strain. Use dark gray instead.

| Token | Light | Dark | Notes |
|-------|-------|------|-------|
| `gridBlack` | `#000000` | `#1A1A1A` | Softened for dark mode |
| `gridEmpty` | `#FFFFFF` | `#121212` | Dark surface, not pure black |
| `gridBorder` | `#E0E0E0` | `#424242` | Higher opacity in dark |
| `cellActive` | `#FDD835` | `#FFD54F` | Brighter yellow for dark mode visibility |
| `wordHighlight` | `#BBDEFB` | `#1976D2` | Stronger blue needed on dark |
| `crossHighlight` | `#E3F2FD` | `#1565C0` (10% opacity) | Subtle on dark |
| `stateCorrect` | `#4CAF50` | `#66BB6A` | Lighter green for dark |
| `stateIncorrect` | `#EF5350` | `#EF9A9A` | Lighter red, less harsh |
| `stateRevealed` | `#FFF9C4` | `#FFB74D` | Muted orange, distinct from yellow |
| `cellText` | `#1F1F1F` | `#E0E0E0` | Light gray, not pure white |
| `cellNumber` | `#424242` | `#B0B0B0` | Medium gray on dark |

### Colorblind-Safe Variants

Provide a **colorblind mode toggle in Settings**. When enabled, swap the correct/incorrect states:

| State | Default | Colorblind Safe |
|-------|---------|-----------------|
| Correct | Green `#4CAF50` | Blue `#1976D2` |
| Incorrect | Red `#EF5350` | Orange `#FF9800` |
| Active cell | Yellow `#FDD835` | Cyan `#00BCD4` |

Also add a **symbol overlay** (small ✓ or ✗ in the corner of verified cells) so color is never the sole indicator.

### Contrast Requirements (WCAG AA minimum, AAA target)

| Pair | Ratio Required | Our values |
|------|---------------|-----------|
| Cell text on empty cell | 4.5:1 (AA) | `#1F1F1F` on `#FFFFFF` = 16.1:1 ✓ |
| Cell number on empty cell | 3:1 (UI element) | `#424242` on `#FFFFFF` = 9.7:1 ✓ |
| Text on active cell (yellow) | 4.5:1 | `#1F1F1F` on `#FDD835` = 8.2:1 ✓ |
| Text on word highlight (light blue) | 4.5:1 | `#1F1F1F` on `#BBDEFB` = 10.4:1 ✓ |

### Flutter Implementation

```dart
// CrosswordColors extension on ThemeData
extension CrosswordColors on ColorScheme {
  Color get gridBlack => brightness == Brightness.dark
      ? const Color(0xFF1A1A1A)
      : const Color(0xFF000000);

  Color get cellActive => brightness == Brightness.dark
      ? const Color(0xFFFFD54F)
      : const Color(0xFFFDD835);

  Color get wordHighlight => brightness == Brightness.dark
      ? const Color(0xFF1976D2)
      : const Color(0xFFBBDEFB);

  // ... etc for all tokens
}
```

---

## Layout & Navigation

### Navigation Structure

**Bottom navigation bar — 4 destinations:**

```
┌──────────────────────────────┐
│                              │
│      Content Area            │
│                              │
├──────────────────────────────┤
│  🏠 Today  📖 Archive  📊 Stats  ⚙️  │
└──────────────────────────────┘
```

| Tab | Icon | Content |
|-----|------|---------|
| Today | Home | Today's puzzle card + streak + recent |
| Archive | Calendar | Browse by date/source/difficulty |
| Stats | Bar chart | Streak, solve times, achievements |
| Settings | Gear | Themes, keyboard, accessibility, sources |

Bottom nav chosen over hamburger drawer because: one-handed thumb access is critical while holding a phone to solve a puzzle; these 4 items are accessed frequently enough to warrant permanent visibility.

### Home Screen Layout (Today tab)

```
┌──────────────────────────────┐
│  Crossword        ⏰ [avatar]│  ← Minimal app bar
├──────────────────────────────┤
│                              │
│   🔥  23-day streak          │  ← Streak — focal point
│                              │
├──────────────────────────────┤
│  ┌────────────────────────┐  │
│  │  TODAY'S CROSSWORD     │  │
│  │  LA Times · Wed Apr 30 │  │  ← Source + date
│  │  ⭐⭐⭐ Medium          │  │  ← Difficulty
│  │  Constructor: B.Haight │  │
│  │                        │  │
│  │  ⏱ In progress: 4:23  │  │  ← or "Best: 8:12 ✓"
│  │  [  SOLVE  ]           │  │  ← Primary CTA
│  └────────────────────────┘  │
│                              │
│  RECENT PUZZLES              │
│  [Yesterday ✓] [Tue ✓] ...  │
│                              │
└──────────────────────────────┘
```

- Today's puzzle card occupies the top ~50% — impossible to miss
- Streak is the first thing visible after app bar — loss-aversion motivator
- `[SOLVE]` changes to `[CONTINUE]` if puzzle is in progress, `[REVIEW]` if complete
- Recent puzzles row shows completion checkmarks — visual streak reinforcement

### Puzzle Solve Screen Layout (Portrait)

```
┌──────────────────────────────┐
│  ← LA Times    ⏱ 4:23  ⋮   │  ← App bar: back, timer, overflow menu
├──────────────────────────────┤
│                              │
│  8-Across: Like a fox        │  ← ClueBar — always visible, full width
│                              │
├──────────────────────────────┤
│                              │
│                              │
│     [  C R O S S W O R D ]   │
│     [     G R I D        ]   │  ← ~55% of screen height
│     [       H E R E      ]   │
│                              │
│                              │
├──────────────────────────────┤
│  ACROSS          DOWN        │
│  1. Greeting     2. Color    │  ← Clue list, scrollable, ~30%
│  5. ▶ Like fox   6. Animal   │  ← Active clue highlighted
│  8. Texture      9. Place    │
├──────────────────────────────┤
│  A B C D E F G H I J K L M   │
│  N O P Q R S T U V W X Y Z   │  ← Custom keyboard, ~15%
│  [⌫ Delete] [✓ Check] [↕]   │
└──────────────────────────────┘
```

**Landscape mode:** Grid on left (~55% width), clue panel on right (~45% width), keyboard hidden (use physical keyboard or toggle button).

### Archive Screen Layout

> **Phase 1:** Archive uses a vertical list, not a calendar — see [topic-17 §5](topic-17-ux-missing-details.md) for Phase 1 list layout, sort options, and filter chips. Calendar view resumes when a daily network source is enabled in Phase 2+.

**Phase 2+ calendar view** (source-delivered daily puzzles only):
- Empty circle: not yet attempted
- Half-filled: in progress
- Filled green: completed
- Gold star: completed under personal best time

Filter bar (Phase 2+): All Sources | [Licensed Source Name] | (+ more)

---

## Micro-Interactions & Animations

This section defines animation and haptic primitives. The game-rule source of truth for when letter entry, check, reveal, hint, completion, and mistake feedback fires is [topic-11-game-mechanics-feedback.md](topic-11-game-mechanics-feedback.md).

### Timing Reference

| Category | Duration | Notes |
|----------|----------|-------|
| Immediate feedback (tap, key) | 50–100ms | Any longer feels laggy |
| State transitions (highlight, focus) | 150–250ms | Smooth but not slow |
| Word/clue transitions | 200–300ms | Moving between words |
| Reveal/check animation | 300–500ms | Cell flip effect |
| Puzzle completion | 600–1000ms | Climactic; worth taking time |
| Screen navigation | 250–350ms | Standard Material transition |

Use `flutter_animate` package for most animations (simpler API than raw `AnimationController`).

Always respect `MediaQuery.of(context).disableAnimations` — reduce or skip animations for users with motion sensitivity enabled.

### Cell & Grid Interactions

| Interaction | Animation | Duration |
|-------------|-----------|----------|
| Tap cell to focus | Background color fade to `cellActive` | 150ms |
| Type a letter | Letter scales from 0.7→1.0 + fade in | 80ms |
| Backspace | Letter fades out, scale 1.0→0.7 | 60ms |
| Direction switch (double-tap) | Word highlight cross-fades to new direction | 200ms |
| Auto-advance to next cell | Focus color slides to next cell | 150ms |
| Auto-advance to next word | Brief flash on old word, fade in on new | 250ms |

### Verification Animations

| Interaction | Animation |
|-------------|-----------|
| Check letter (correct) | Cell background flips to `stateCorrect` green (card flip, 400ms) |
| Check letter (incorrect) | Cell shakes horizontally ±4dp × 3 (200ms) + flips to red |
| Reveal letter | Card flip reveals answer in `stateRevealed` yellow (400ms) |
| Check word | Cells animate sequentially left→right with 30ms stagger |
| Reveal word | Same stagger, 40ms between cells |

### Word & Puzzle Completion

| Event | Animation |
|-------|-----------|
| Complete a word | Cells in word pulse with a soft green glow (300ms, then fade) |
| Complete the puzzle | 1. Grid cells all flash correct-green in wave (500ms) → 2. Confetti burst from top (800ms) → 3. Stats card slides up from bottom |

### Haptic Feedback

| Event | Pattern | Duration |
|-------|---------|----------|
| Correct letter entry | `HapticFeedback.lightImpact()` | ~50ms |
| Backspace | `HapticFeedback.selectionClick()` | ~30ms |
| Direction switch | `HapticFeedback.selectionClick()` | ~30ms |
| Word completion | `HapticFeedback.mediumImpact()` | ~80ms |
| Puzzle completion | Three pulses: light → medium → heavy (300ms total) | Custom via `Vibrate` package |
| Error / incorrect | `HapticFeedback.vibrate()` (short buzz) | ~80ms |

Always provide a **haptics toggle in Settings** — some users find vibration distracting or use devices that lack good haptics.

---

## Onboarding

### First-Run Flow

**Principle:** Teach by doing, not by reading. Keep mandatory tutorial to under 90 seconds.

**Step 1 — Tap a cell** (mandatory, cannot skip)
- Dim the grid except one cell; show pulsing tap indicator
- Copy: "Tap a cell to start solving"

**Step 2 — Type a letter** (mandatory)
- After cell is focused, hint arrow points to keyboard
- Letter appears; brief "nice" animation
- Auto-advances; copy: "Letters advance automatically"

**Step 3 — Switch direction** (optional, shown contextually)
- First time user reaches a down clue, show tooltip: "Double-tap to switch direction"
- Not shown in mandatory flow

**Step 4 — Check / Reveal** (deferred)
- Shown only when user taps the overflow menu (⋮) for the first time
- Tooltip explains Check and Reveal options inline

**Skip:** Always available top-right. Users who skip see a "How to play" link in Settings permanently.

**Revisit:** Settings > Help > Tutorial (replays the interactive demo on a sample puzzle).

---

## Empty & Error States

Phase 1 is import-first. Network source browsing is not available until a source is legally cleared, so topic #16 overrides any earlier "Browse Sources" or "Solve Today's" empty-state copy for the Android MVP.

### Empty States

| State | Illustration | Headline | Body | Action |
|-------|-------------|---------|------|--------|
| No puzzles imported | Grid with question marks | "No puzzles yet" | "Import a `.puz` or `.ipuz` file to start solving." | [Import Puzzle] |
| Puzzle source offline | Signal with X | "Source unavailable" | "This source couldn't be reached. Try another." | Hide in Phase 1; use only after licensed sources exist |
| Archive empty | Calendar outline | "No past puzzles" | "Solved puzzles will appear here." | [Import Puzzle] |
| Stats — no data | Bar chart outline | "No stats yet" | "Complete your first puzzle to see stats." | [Import Puzzle] or [Continue] |

### Error States

| Scenario | Message | Recovery |
|----------|---------|----------|
| No internet, puzzle not cached | "No connection — this puzzle isn't available offline." | Future source feature only; do not show in Phase 1 |
| No internet, puzzle cached | Silent — show cached puzzle with subtle "Offline" chip | None needed |
| Puzzle file corrupt / parse error | "This puzzle couldn't load. It may be a format issue." | [Report] + [Skip] |
| Download timeout | "Took too long. Check your connection." | [Retry] |

Use **friendly tone, no technical jargon**. Always provide one clear action button.

---

## Loading States

- Show **skeleton screen** if loading takes 300ms or longer
- Skeleton matches final layout exactly — no layout shift on load
- Use **wave/shimmer animation** (left-to-right) to make longer loads feel responsive without resorting to a generic spinner
- Flutter package: `shimmer`

**Skeleton for Solve screen:**
- App bar: solid shimmer bar
- ClueBar: shimmer text block (75% width)
- Grid: shimmer grid matching expected dimensions
- Clue list: 5–6 shimmer rows

If still loading after 5 seconds, add secondary text: "Still loading…" and a Retry option.

---

## Streaks & Motivation

### Streak Display

- **Home screen**: Flame emoji + day count as the first element below the app bar — this is the primary retention hook
- **Milestone celebrations** at: 7, 14, 30, 100, 365 days — full-screen lottie animation + share card
- **Streak freeze** (future premium feature): warn user on day 4 of current streak that a freeze is available; prevents churn when they miss a day

### Stats Screen

Show in this priority order:
1. Current streak + longest streak
2. Solve times: today / 7-day average / personal best
3. Total puzzles solved (lifetime)
4. Completion rate (% of started puzzles finished)
5. Difficulty breakdown (pie or bar chart — easy/medium/hard/themeless)
   - **Phase 1 empty state:** Most imported puzzles have no difficulty metadata. If fewer than 3 puzzles have a difficulty value, hide the chart entirely and show a muted caption: "Difficulty breakdown will appear as you solve more puzzles." Do not show a nearly-empty chart.

Keep stats screen clean — one screen, no nested tabs. Dense but not cluttered.

---

## App Icon & Branding Direction

### Icon Concept

- **Shape**: Rounded square (standard iOS/Android adaptive icon)
- **Core symbol**: Partial crossword grid (3×3 or 4×4 section) with 1–2 filled black squares and 1 bold letter visible
- **Style**: Flat with subtle depth (light shadow on grid cells) — not skeuomorphic, not pure flat
- **Color**: Deep blue (`#1565C0`) grid background with white cell letter + warm orange/gold accent on one cell
- **What to avoid**: Realistic pencils, tiny unreadable clue text, a full 15×15 grid (illegible at icon size)

### Tone & Voice

- **Name**: Crosscue — short, cue/clue-adjacent, and specific enough to avoid generic "Crossword Pro" positioning.
- **UI copy voice**: Warm, encouraging, never condescending — "Nice one!" not "Correct." Quiet when the user is solving (no distracting tooltips mid-puzzle)
- **Error copy**: Conversational — "Couldn't load that puzzle" not "Error 503"

---

## Design Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Primary font | Roboto (built-in) | Material 3 default; no extra dependency |
| Timer font | Roboto Mono | Tabular digits prevent layout shift |
| Seed color | `#2196F3` Material Blue | Professional, puzzle-appropriate, good M3 palette |
| Dynamic color | Yes (Android 12+), fixed fallback | Best of both: personalisation + consistency |
| Dark mode grid black | `#1A1A1A` (not `#000000`) | Reduces eye strain per Material Design guidance |
| Navigation | Bottom nav, 4 tabs | One-handed access during solving |
| Onboarding | Interactive, progressive, skippable | Low friction; contextual teaching > front-loaded tutorial |
| Haptics | On by default, toggleable | Elevates feel; must be dismissable |
| Streak position | First element on home screen | Primary retention driver (loss-aversion psychology) |
| Animations | `flutter_animate` package | Simpler API than raw controllers; disable via `disableAnimations` |
| Loading | Shimmer skeleton (wave) | Keeps layout stable and gives visible progress while content loads |
| Colorblind support | Toggle in Settings (orange/blue swap) | Ensures color is never the sole state indicator |

---

## Flutter Package Additions (beyond architecture doc)

| Package | Purpose |
|---------|---------|
| `dynamic_color` | Android 12+ Material You wallpaper-based palette |
| `shimmer` | Wave skeleton loading screens |
| `flutter_animate` | Micro-interaction and animation DSL |
| Roboto Mono asset files | Bundled timer font; no runtime network dependency |
| Flutter `services` library | Built-in `HapticFeedback.lightImpact()`, `selectionClick()`, `mediumImpact()`, etc.; no package dependency |
| `vibration` | Optional custom haptic patterns for puzzle completion; check device support and Android permission requirements |
| `home_widget` | Android/iOS home screen streak widget (Phase 2) |
