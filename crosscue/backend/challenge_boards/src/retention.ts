// Scheduled retention purge for the audit-only board_events table.

import type { Env } from "./types.ts";
import { addDays, utcNow } from "./util.ts";

export const boardEventsRetentionDays = 14;

export const purgeChunkSize = 500;

// Daily retention for the audit-only board_events table. challenge_results is
// intentionally retained because lifetime leaderboards are computed live from it
// (no player_board_stats rollover in v1); purging it would shrink lifetime stats.

// Daily retention for the audit-only board_events table. challenge_results is
// intentionally retained because lifetime leaderboards are computed live from it
// (no player_board_stats rollover in v1); purging it would shrink lifetime stats.
export async function purgeOldBoardEvents(env: Env): Promise<number> {
  const cutoff = addDays(utcNow(), -boardEventsRetentionDays);
  let deleted = 0;
  for (;;) {
    const batch = await env.DB.prepare(
      "select id from board_events where created_at < ? limit ?",
    )
      .bind(cutoff, purgeChunkSize)
      .all<{ id: string }>();
    const ids = (batch.results ?? []).map((row) => row.id);
    if (ids.length === 0) break;
    const placeholders = ids.map(() => "?").join(",");
    await env.DB.prepare(
      `delete from board_events where id in (${placeholders})`,
    )
      .bind(...ids)
      .run();
    deleted += ids.length;
    if (ids.length < purgeChunkSize) break;
  }
  return deleted;
}
