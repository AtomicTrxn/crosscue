// Scheduled sweep for two board states that should not exist: open with no
// active membership, and owned by someone who has left.
//
// Current code cannot produce either. boardDepartureStatements() guards both
// writes in SQL — the empty-board close carries `not exists (select 1 from
// memberships ...)` and the ownership transfer selects its successor inline —
// and those subqueries evaluate inside the batch, after the membership close
// commits. There is no read-then-write window to lose, so this sweep is not
// covering a live race.
//
// It exists for rows written before that guarding landed (#13375a8), which no
// later request revisits: a board stuck open is never reopened, and a board
// owned by a departed player only changes hands when someone leaves. Nothing
// repairs those on its own. Keeping the sweep on the cron also means a future
// regression in the departure SQL degrades into a day of wrong state rather
// than a permanent one.
//
// Chunked like purgeOldBoardEvents so it cannot blow up on a large boards
// table. On healthy data it is a no-op and writes nothing — tested, because a
// sweep that "repairs" correct rows would be worse than no sweep.

import type { Env } from "./types.ts";
import { utcNow } from "./util.ts";

export const reconcileChunkSize = 500;
// At most 24 D1 statements (8 close updates + 8 two-statement owner batches)
// per invocation. Together with the bounded purge and two heartbeat writes,
// the scheduled handler stays below D1's 50-query free-plan limit.
export const reconcileMaxChunks = 8;
export const reconcileHeartbeatKey = "last_board_reconcile_at";

// Repair 1: a board with deleted_at null but no active membership is stuck
// open. This must run before reassignOrphanedOwners — closing it first means
// an empty board never gets handed a new owner.
export async function closeEmptyBoards(env: Env): Promise<number> {
  let repaired = 0;
  for (let chunk = 0; chunk < reconcileMaxChunks; chunk += 1) {
    const result = await env.DB.prepare(
      `with candidates as (
         select b.id
         from boards b
         where b.deleted_at is null
           and not exists (
             select 1 from memberships m
             where m.board_id = b.id and m.left_at is null
           )
         order by b.id
         limit ?
       )
       update boards
       set deleted_at = ?
       where id in (select id from candidates)
         and deleted_at is null
         and not exists (
           select 1 from memberships m
           where m.board_id = boards.id and m.left_at is null
         )`,
    )
      .bind(reconcileChunkSize, utcNow())
      .run();
    const repairedThisChunk = Number(result.meta.changes ?? 0);
    repaired += repairedThisChunk;
    if (repairedThisChunk < reconcileChunkSize) break;
  }
  return repaired;
}

// Both statements below use this byte-identical candidate set. D1 batch()
// executes them sequentially in one transaction: inserting the events first
// does not change board or membership state, so the following update targets
// exactly the same rows. If either statement fails, both roll back. Event IDs
// are opaque text keys, so SQL can generate one random 128-bit value per row
// without expanding the batch into hundreds of per-board statements.
const repairableOwnersSql = `
  select
    b.id,
    (
      select successor.player_id
      from memberships successor
      where successor.board_id = b.id and successor.left_at is null
      order by successor.joined_at, successor.player_id
      limit 1
    ) as new_owner_id
  from boards b
  where b.deleted_at is null
    and (
      b.owner_player_id is null
      or not exists (
        select 1 from memberships current_owner
        where current_owner.board_id = b.id
          and current_owner.player_id = b.owner_player_id
          and current_owner.left_at is null
      )
    )
    and exists (
      select 1 from memberships active
      where active.board_id = b.id and active.left_at is null
    )
  order by b.id
  limit ?
`;

// Repair 2: a board with deleted_at null whose owner_player_id is null, or
// no longer an active member, gets reassigned to the earliest-joined active
// member — the same succession rule leaveBoard and deletePlayer use (order
// by joined_at, player_id). The owner update and its 'owner_changed' event
// land in the same batch, per the atomicity fix those two functions made.
export async function reassignOrphanedOwners(env: Env): Promise<number> {
  let repaired = 0;
  for (let chunk = 0; chunk < reconcileMaxChunks; chunk += 1) {
    const now = utcNow();
    const [events, updates] = await env.DB.batch([
      env.DB
        .prepare(
          `with repairable as (${repairableOwnersSql})
           insert into board_events (
             id, board_id, actor_player_id, event_type, created_at
           )
           select
             lower(hex(randomblob(16))),
             id,
             new_owner_id,
             'owner_changed',
             ?
           from repairable`,
        )
        .bind(reconcileChunkSize, now),
      env.DB
        .prepare(
          `with repairable as (${repairableOwnersSql})
           update boards
           set owner_player_id = (
             select repairable.new_owner_id
             from repairable
             where repairable.id = boards.id
           )
           where id in (select id from repairable)`,
        )
        .bind(reconcileChunkSize),
    ]);
    const eventsWritten = Number(events.meta.changes ?? 0);
    const ownersUpdated = Number(updates.meta.changes ?? 0);
    if (eventsWritten !== ownersUpdated) {
      throw new Error(
        `reconcile owner/event mismatch: ${ownersUpdated} owners, ${eventsWritten} events`,
      );
    }
    repaired += ownersUpdated;
    if (ownersUpdated < reconcileChunkSize) break;
  }
  return repaired;
}

export async function recordReconcileHeartbeat(
  env: Env,
  at: string = utcNow(),
): Promise<void> {
  await env.DB.prepare(
    `insert into ops_meta (key, value) values (?, ?)
     on conflict(key) do update set value = excluded.value`,
  )
    .bind(reconcileHeartbeatKey, at)
    .run();
}

export async function reconcileHealth(
  env: Env,
): Promise<{ lastReconcileAt: string | null }> {
  const row = await env.DB.prepare("select value from ops_meta where key = ?")
    .bind(reconcileHeartbeatKey)
    .first<{ value: string }>();
  return { lastReconcileAt: row?.value ?? null };
}

export type ReconcileResult = {
  boardsClosed: number;
  ownersReassigned: number;
};

export async function reconcileBoards(env: Env): Promise<ReconcileResult> {
  // Order matters: close empty boards before touching ownership, so an
  // empty board never gets handed a new owner.
  const boardsClosed = await closeEmptyBoards(env);
  const ownersReassigned = await reassignOrphanedOwners(env);
  return { boardsClosed, ownersReassigned };
}
