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

import { eventStatement } from "./membership.ts";
import type { Env } from "./types.ts";
import { utcNow } from "./util.ts";

export const reconcileChunkSize = 500;

// Repair 1: a board with deleted_at null but no active membership is stuck
// open. This must run before reassignOrphanedOwners — closing it first means
// an empty board never gets handed a new owner.
export async function closeEmptyBoards(env: Env): Promise<number> {
  let repaired = 0;
  for (;;) {
    const candidates = await env.DB.prepare(
      `select b.id from boards b
       where b.deleted_at is null
         and not exists (
           select 1 from memberships m
           where m.board_id = b.id and m.left_at is null
         )
       limit ?`,
    )
      .bind(reconcileChunkSize)
      .all<{ id: string }>();
    const ids = (candidates.results ?? []).map((row) => row.id);
    if (ids.length === 0) break;

    const now = utcNow();
    for (const id of ids) {
      await env.DB.batch([
        env.DB.prepare(
          "update boards set deleted_at = ? where id = ? and deleted_at is null",
        ).bind(now, id),
      ]);
      repaired += 1;
    }
    if (ids.length < reconcileChunkSize) break;
  }
  return repaired;
}

// Repair 2: a board with deleted_at null whose owner_player_id is null, or
// no longer an active member, gets reassigned to the earliest-joined active
// member — the same succession rule leaveBoard and deletePlayer use (order
// by joined_at, player_id). The owner update and its 'owner_changed' event
// land in the same batch, per the atomicity fix those two functions made.
export async function reassignOrphanedOwners(env: Env): Promise<number> {
  let repaired = 0;
  for (;;) {
    const candidates = await env.DB.prepare(
      `select b.id from boards b
       where b.deleted_at is null
         and (
           b.owner_player_id is null
           or not exists (
             select 1 from memberships m
             where m.board_id = b.id and m.player_id = b.owner_player_id
               and m.left_at is null
           )
         )
       limit ?`,
    )
      .bind(reconcileChunkSize)
      .all<{ id: string }>();
    const ids = (candidates.results ?? []).map((row) => row.id);
    if (ids.length === 0) break;

    let repairedThisChunk = 0;
    for (const id of ids) {
      const next = await env.DB.prepare(
        `select player_id from memberships
         where board_id = ? and left_at is null
         order by joined_at, player_id
         limit 1`,
      )
        .bind(id)
        .first<{ player_id: string }>();
      // No active member left: the board emptied out concurrently with this
      // sweep. closeEmptyBoards will pick it up on the next run.
      if (!next) continue;

      const now = utcNow();
      await env.DB.batch([
        env.DB.prepare(
          "update boards set owner_player_id = ? where id = ? and deleted_at is null",
        ).bind(next.player_id, id),
        eventStatement(env, id, next.player_id, "owner_changed", now),
      ]);
      repaired += 1;
      repairedThisChunk += 1;
    }
    // Every candidate was skipped, so the next scan would return this same
    // chunk and spin forever. Nothing more is repairable this run; the next
    // run picks them up once closeEmptyBoards has closed them.
    if (repairedThisChunk === 0) break;
    if (ids.length < reconcileChunkSize) break;
  }
  return repaired;
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
