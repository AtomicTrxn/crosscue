# Research Topic #15 — Streak & Stats Algorithm

Status: Resolved
Implementation Status: ✅ Implemented — Sprint 7 stats screen, streak algorithm, completion breakdown, and personal bests shipped
Owner: Codex

## Research Question

What rules determine streaks, solve dates, completion labels, personal bests, milestones, and stats aggregates?

## Decision To Unblock

Which stats fields and date rules must be represented in the initial Drift schema so the app does not need a painful migration after users already have solve history?

## Recommendation

Compute streaks from completed solve sessions using the user's local calendar day at the moment the puzzle is completed. Store `solved_date_local`, `solved_timezone`, and `completion_type` on each completed session so stats remain stable even if the user later changes time zones.

For Phase 1, keep stats simple and transparent:

- Clean solves count toward streaks and personal bests.
- Solves with checks count toward streaks but not clean personal bests.
- Solves with reveal letter/word count toward streaks but are labeled `Solved with hints` and excluded from clean personal bests.
- Reveal puzzle is labeled `Revealed` and does not count toward streaks.
- All solve timing should use active elapsed timer time, not wall-clock time.

This matches topic #11's habit-friendly lean: smaller hints do not punish daily habit, but clean stats preserve skill signal.

## Completion Types

| `completion_type` | Meaning | Counts Toward Streak | Eligible For Clean PB | Display Label |
|-------------------|---------|----------------------|-----------------------|---------------|
| `clean` | Completed with no checks and no reveals | Yes | Yes | Clean solve |
| `checked` | Completed after one or more check actions, no reveals | Yes | No | Solved with checks |
| `hinted` | Completed after reveal letter/word, but not reveal puzzle | Yes | No | Solved with hints |
| `revealed` | User revealed the whole puzzle | No | No | Revealed |

Priority when deriving type:

1. If `status == revealed` or reveal puzzle used: `revealed`.
2. Else if `used_reveal == true`: `hinted`.
3. Else if `used_check == true`: `checked`.
4. Else: `clean`.

## Solve Date And Time Zone

### Rule

Store the local calendar date at completion:

- `completed_at`: exact UTC timestamp (matches `solve_sessions.completed_at` column in topic-02).
- `solved_date_local`: date string, e.g. `2026-05-01`.
- `solved_timezone`: IANA timezone if available, e.g. `America/New_York`.

Streaks should use `solved_date_local`, not UTC date, because streaks are a human habit concept.

### Midnight Edge Cases

| Scenario | Rule |
|----------|------|
| Start before midnight, finish after midnight | Counts for finish date. |
| App open across timezone change | Completion uses current device timezone at completion. |
| User changes clock manually | Trust device time; this is acceptable for MVP. |
| Same puzzle completed twice in one day | Count the best streak-eligible completion once for that day. |
| Imported old puzzle solved today | Counts for today's streak if completed today. |

Rationale: completion date is easier to explain than publish date, especially because Phase 1 is import-first and may not have daily source metadata.

## Streak Algorithm

Input: all solve sessions with `completion_type` in `clean`, `checked`, `hinted`.

Derive unique solved dates:

1. Query completed sessions where `completion_type != revealed`.
2. Extract distinct `solved_date_local`.
3. Sort descending.
4. Current streak:
   - If today is solved, start from today.
   - Else if yesterday is solved, start from yesterday.
   - Else current streak is `0`.
   - Count consecutive dates backward.
5. Longest streak:
   - Sort all solved dates ascending.
   - Count the longest consecutive run.

Allow yesterday as the start so a user checking the app in the morning before solving today still sees yesterday's streak rather than zero.

Pseudo-code:

```dart
int currentStreak(Set<LocalDate> solvedDates, LocalDate today) {
  final start = solvedDates.contains(today)
      ? today
      : solvedDates.contains(today.minusDays(1))
          ? today.minusDays(1)
          : null;
  if (start == null) return 0;

  var count = 0;
  var cursor = start;
  while (solvedDates.contains(cursor)) {
    count += 1;
    cursor = cursor.minusDays(1);
  }
  return count;
}
```

> **Dart implementation note:** Dart has no native `LocalDate` type. Represent it as a `String` (`yyyy-MM-dd`, e.g. `"2026-05-01"`) stored in `solved_date_local`. Use `DateFormat('yyyy-MM-dd').format(DateTime.now())` from the `intl` package to extract the current local date at completion time. The `minusDays(1)` operation becomes `DateTime.parse(dateStr).subtract(const Duration(days: 1))` formatted back to a string. The `Set<String>` approach is sufficient for streak calculations and avoids any third-party date library dependency.

## Stats Aggregates

### Home Screen

| Stat | Calculation |
|------|-------------|
| Current streak | Current streak algorithm above. |
| Today's status | Any streak-eligible completion with `solved_date_local == today`. |
| Recent puzzles | Most recent sessions by `last_played_at`, grouped by puzzle. |

### Stats Screen

Keep one screen, no nested tabs for MVP.

| Stat | Calculation |
|------|-------------|
| Current streak | Current streak algorithm. |
| Longest streak | Longest consecutive run of streak-eligible solved dates. |
| Total puzzles solved | Count sessions with `completion_type` in `clean`, `checked`, `hinted`. |
| Clean solves | Count sessions with `completion_type == clean`. |
| Hinted/checked solves | Count `checked` + `hinted`. |
| Revealed puzzles | Count `revealed`; display separately, not as solves. |
| Average solve time | Average `elapsed_ms` for `clean`, `checked`, `hinted`; exclude revealed. |
| 7-day average | Average elapsed for completed sessions with `solved_date_local` in last 7 local days; exclude revealed. |
| Personal best | Minimum `elapsed_ms` for `completion_type == clean`, optionally same grid size only. |
| Completion rate | Completed or revealed sessions divided by started sessions. |
| Difficulty/source breakdown | Group by `difficulty` and `source_id` when metadata exists. |

### Personal Best Scope

For MVP, personal best should be computed per grid size:

- 15x15 PB.
- 21x21 PB.
- Mini PB if supported.

Do not compare minis against full-size puzzles.

## Milestones

Milestone thresholds:

- 7 days.
- 14 days.
- 30 days.
- 100 days.
- 365 days.

Trigger a milestone celebration only once per threshold per user:

- Store `streak_milestones_shown` in `app_settings` as JSON list or separate table.
- Show after completion if the new current streak exactly reaches a threshold.
- If restore/import creates a past milestone, do not replay all old milestones.

## Drift Schema Additions

Topic #2 already includes most session fields. Add/confirm these fields before initial migration:

`solve_sessions`:

- `completion_type`
- `completed_at`
- `solved_date_local`
- `solved_timezone`
- `elapsed_ms`
- `check_count`
- `reveal_count`
- `mistake_count`
- `used_check`
- `used_reveal`
- `clean_solve_eligible`

`puzzles`:

- `width`
- `height`
- `difficulty`
- `source_id`
- `publish_date`

`app_settings`:

- `streak_milestones_shown`

Indexes:

- `solve_sessions(solved_date_local)`
- `solve_sessions(completion_type)`
- `solve_sessions(puzzle_id, completed_at)`

## Interaction With Topic #11

Topic #11 owns gameplay mechanics; this topic owns stats interpretation.

Mapping:

- `checkCount > 0` or `usedCheck == true` → not clean.
- `revealCount > 0` or `usedReveal == true` → hinted unless reveal puzzle.
- `status == revealed` → not streak-eligible.
- `cleanSolveEligible == true` and no checks/reveals → clean.

## Open Decisions

| Decision | Current Lean | Notes |
|----------|--------------|-------|
| Do reveal letter/word preserve streak? | Yes | Habit-friendly; still excludes clean stats. |
| Does reveal puzzle preserve streak? | No | Fully revealed puzzle is not solved. |
| Do checks preserve streak? | Yes | Common helper feature; not clean. |
| Should imported old puzzles count toward streak? | Yes by completion date | Phase 1 is import-first, so this keeps behavior simple. |
| Personal best by source or grid size? | Grid size first | Source-specific PB can come later. |
| Should paused time count? | No if timer is explicitly paused | Use elapsed active timer time. |

## Implementation Checklist

1. Add `solved_date_local`, `solved_timezone`, and `completion_type` to the Drift schema before first migration ships.
2. Add a `StatsService` or `StatsRepository` that derives streaks from solve sessions.
3. Add unit tests for current streak, longest streak, midnight crossing, yesterday-not-yet-today behavior, and reveal puzzle exclusion.
4. Add unit tests for completion type derivation from `used_check`, `used_reveal`, and status.
5. Add milestone tracking in `app_settings`.
6. Ensure analytics/feedback topic #5 does not collect precise solve history externally.
7. Revisit reveal/streak policy with product owner before implementation locks.

## Sources

- Game mechanics policy: [topic-11-game-mechanics-feedback.md](topic-11-game-mechanics-feedback.md)
- Drift schema: [topic-02-drift-database-schema.md](topic-02-drift-database-schema.md)
- Backend/sync date dedupe note: [topic-09-backend-sync-decision.md](topic-09-backend-sync-decision.md)
- Design stats screen guidance: [topic-10-design-ux-research.md](topic-10-design-ux-research.md)
