// Scheduled retention purge for the audit-only board_events table.

import type { Env } from "./types.ts";
import { addDays, utcNow } from "./util.ts";

export const boardEventsRetentionDays = 14;

export const purgeChunkSize = 500;
// Eight set-based deletes purge up to 4,000 events while reserving D1's
// remaining free-plan query budget for reconciliation and heartbeat writes.
export const purgeMaxChunks = 8;

// Daily retention for the audit-only board_events table. challenge_results is
// intentionally retained because lifetime leaderboards are computed live from it
// (no player_board_stats rollover in v1); purging it would shrink lifetime stats.
export async function purgeOldBoardEvents(env: Env): Promise<number> {
  const cutoff = addDays(utcNow(), -boardEventsRetentionDays);
  let deleted = 0;
  for (let chunk = 0; chunk < purgeMaxChunks; chunk += 1) {
    const result = await env.DB.prepare(
      `delete from board_events
       where id in (
         select id
         from board_events
         where created_at < ?
         order by created_at, id
         limit ?
       )`,
    )
      .bind(cutoff, purgeChunkSize)
      .run();
    const deletedThisChunk = Number(result.meta.changes ?? 0);
    deleted += deletedThisChunk;
    if (deletedThisChunk < purgeChunkSize) break;
  }
  return deleted;
}

// Retention heartbeat (#262). The scheduled handler records when it last ran
// in ops_meta; GET /health/retention exposes it so an external weekly check
// can alert if the cron silently stops (the symptom is otherwise invisible —
// unbounded board_events growth with no error).
export const retentionHeartbeatKey = "last_retention_purge_at";

export async function recordRetentionHeartbeat(
  env: Env,
  at: string = utcNow(),
): Promise<void> {
  await env.DB.prepare(
    `insert into ops_meta (key, value) values (?, ?)
     on conflict(key) do update set value = excluded.value`,
  )
    .bind(retentionHeartbeatKey, at)
    .run();
}

export async function retentionHealth(
  env: Env,
): Promise<{ lastPurgeAt: string | null }> {
  const row = await env.DB.prepare("select value from ops_meta where key = ?")
    .bind(retentionHeartbeatKey)
    .first<{ value: string }>();
  return { lastPurgeAt: row?.value ?? null };
}
