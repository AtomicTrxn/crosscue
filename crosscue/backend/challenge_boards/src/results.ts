// Honor-system result submission with bounded sanity checks.

import { defaultSourceId, minPlausibleElapsedMs } from "./constants.ts";
import { readBody } from "./http.ts";
import type { Auth, Env, JsonValue } from "./types.ts";
import { utcNow } from "./util.ts";
import { validateCompletionType, validateDateOnly, validateIsoDateTime, validatePositiveInteger, validateRequiredString } from "./validation.ts";

export async function submitResult(
  request: Request,
  env: Env,
  auth: Auth,
): Promise<JsonValue> {
  const body = await readBody(request);
  const sourceId = validateRequiredString(body.sourceId, "source_id", 80);
  const sourcePuzzleId = validateRequiredString(
    body.sourcePuzzleId,
    "source_puzzle_id",
    120,
  );
  const completedAt = validateIsoDateTime(body.completedAt, "completed_at");
  const elapsedMs = validatePositiveInteger(body.elapsedMs, "elapsed_ms");
  const completionType = validateCompletionType(body.completionType);
  // Never trust the client flag on its own: a non-clean completion (checked,
  // hinted, revealed, unsolved) can never be clean-ranking eligible (#228).
  const cleanSolveEligible =
    body.cleanSolveEligible === true && completionType === "clean" ? 1 : 0;
  const puzzleTitle =
    typeof body.puzzleTitle === "string" ? body.puzzleTitle.slice(0, 160) : null;
  const publishedOn =
    typeof body.publishedOn === "string"
      ? validateDateOnly(body.publishedOn, "published_on")
      : null;
  const now = utcNow();

  if (sourceId !== defaultSourceId || publishedOn == null) {
    return { accepted: false, reason: "not_challenge_daily_mini" };
  }

  if (elapsedMs < minPlausibleElapsedMs) {
    return { accepted: false, reason: "implausible_elapsed_ms" };
  }

  // Allow a day of clock skew, but a completion claimed further in the
  // future is a client bug or forgery. Past timestamps stay accepted: the
  // offline outbox legitimately delivers results late.
  if (Date.parse(completedAt) > Date.now() + 86_400_000) {
    return { accepted: false, reason: "implausible_completed_at" };
  }

  const hasBoardForSource = await env.DB.prepare(
    `select 1 as ok
     from memberships m
     join boards b on b.id = m.board_id
     where m.player_id = ? and m.left_at is null
       and b.deleted_at is null and b.source_id = ?
     limit 1`,
  )
    .bind(auth.player.id, sourceId)
    .first<{ ok: number }>();
  if (!hasBoardForSource) {
    return { accepted: false, reason: "no_active_source_board" };
  }

  await env.DB.prepare(
    `insert into challenge_results (
      id, player_id, source_id, source_puzzle_id, puzzle_title, published_on,
      completed_at, elapsed_ms, completion_type, clean_solve_eligible,
      created_at, updated_at
    ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    on conflict(player_id, source_id, source_puzzle_id) do update set
      puzzle_title = excluded.puzzle_title,
      published_on = excluded.published_on,
      completed_at = excluded.completed_at,
      elapsed_ms = excluded.elapsed_ms,
      completion_type = excluded.completion_type,
      clean_solve_eligible = excluded.clean_solve_eligible,
      updated_at = excluded.updated_at`,
  )
    .bind(
      crypto.randomUUID(),
      auth.player.id,
      sourceId,
      sourcePuzzleId,
      puzzleTitle,
      publishedOn,
      completedAt,
      elapsedMs,
      completionType,
      cleanSolveEligible,
      now,
      now,
    )
    .run();

  return { accepted: true };
}
