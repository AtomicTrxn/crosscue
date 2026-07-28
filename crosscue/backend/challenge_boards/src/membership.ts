// Board-membership lookups, invite verification, and audit events.

import { ApiError } from "./http.ts";
import type { BoardRow, Env, JsonValue } from "./types.ts";
import { sha256, utcNow } from "./util.ts";

export async function requireActiveBoardMember(
  env: Env,
  playerId: string,
  boardId: string,
): Promise<BoardRow> {
  const board = await env.DB.prepare(
    `select b.id, b.name, b.source_id, b.ranking_mode, b.owner_player_id,
            b.invite_expires_at, b.invite_version, count(active.player_id) as player_count
     from boards b
     join memberships mine on mine.board_id = b.id
       and mine.player_id = ? and mine.left_at is null
     left join memberships active on active.board_id = b.id
       and active.left_at is null
     where b.id = ? and b.deleted_at is null
     group by b.id`,
  )
    .bind(playerId, boardId)
    .first<BoardRow>();
  if (!board) {
    throw new ApiError(404, "board_not_found", "Board not found.");
  }
  return board;
}

export async function activeBoardCount(env: Env, playerId: string): Promise<number> {
  const row = await env.DB.prepare(
    "select count(*) as count from memberships where player_id = ? and left_at is null",
  )
    .bind(playerId)
    .first<{ count: number }>();
  return Number(row?.count ?? 0);
}

export async function activeMemberCount(env: Env, boardId: string): Promise<number> {
  const row = await env.DB.prepare(
    "select count(*) as count from memberships where board_id = ? and left_at is null",
  )
    .bind(boardId)
    .first<{ count: number }>();
  return Number(row?.count ?? 0);
}

export async function isActiveMember(
  env: Env,
  playerId: string,
  boardId: string,
): Promise<boolean> {
  const row = await env.DB.prepare(
    `select 1 as ok from memberships
     where player_id = ? and board_id = ? and left_at is null`,
  )
    .bind(playerId, boardId)
    .first<{ ok: number }>();
  return row?.ok === 1;
}

export async function verifyInvite(
  env: Env,
  boardId: string,
  token: string,
): Promise<boolean> {
  const hash = await sha256(token);
  const row = await env.DB.prepare(
    `select 1 as ok from boards
     where id = ? and invite_code_hash = ? and invite_expires_at >= ?
       and deleted_at is null`,
  )
    .bind(boardId, hash, utcNow())
    .first<{ ok: number }>();
  return row?.ok === 1;
}

export function eventStatement(
  env: Env,
  boardId: string,
  actorPlayerId: string,
  eventType: string,
  now: string,
): D1PreparedStatement {
  return env.DB.prepare(
    `insert into board_events (
      id, board_id, actor_player_id, event_type, created_at
    ) values (?, ?, ?, ?, ?)`,
  ).bind(crypto.randomUUID(), boardId, actorPlayerId, eventType, now);
}

/**
 * Builds every D1 statement needed to depart one board. Callers append these
 * to the same batch as any route-level cleanup so a failed board deletion or
 * ownership transfer cannot leave a closed membership behind.
 *
 * The statements execute in order: close membership, record leave, soft-delete
 * an empty board, then (for an owner departure) transfer ownership and record
 * the new owner. The owner is selected inside the batch after the membership
 * closes, so the update sees the post-departure active-member set.
 */
export function boardDepartureStatements(
  env: Env,
  board: BoardRow,
  departingPlayerId: string,
  now: string,
): { statements: D1PreparedStatement[]; boardDeleted: boolean } {
  const statements = [
    env.DB.prepare(
      `update memberships
       set left_at = ?, membership_state = 'left'
       where board_id = ? and player_id = ? and left_at is null`,
    ).bind(now, board.id, departingPlayerId),
    eventStatement(env, board.id, departingPlayerId, "leave", now),
    env.DB.prepare(
      `update boards
       set deleted_at = ?
       where id = ? and deleted_at is null
         and not exists (
           select 1 from memberships
           where board_id = ? and left_at is null
         )`,
    ).bind(now, board.id, board.id),
  ];

  if (board.owner_player_id === departingPlayerId) {
    statements.push(
      env.DB.prepare(
        `update boards
         set owner_player_id = (
           select player_id from memberships
           where board_id = ? and left_at is null
           order by joined_at, player_id
           limit 1
         )
         where id = ? and deleted_at is null
           and owner_player_id = ?`,
      ).bind(board.id, board.id, departingPlayerId),
      env.DB.prepare(
        `insert into board_events (
          id, board_id, actor_player_id, event_type, created_at
        )
        select ?, id, owner_player_id, 'owner_changed', ?
        from boards
        where id = ? and deleted_at is null
          and owner_player_id is not null
          and owner_player_id <> ?`,
      ).bind(
        crypto.randomUUID(),
        now,
        board.id,
        departingPlayerId,
      ),
    );
  }

  return {
    statements,
    boardDeleted: Number(board.player_count ?? 1) <= 1,
  };
}

export function inviteUrl(env: Env, boardId: string, secret: string): string {
  return `${env.PUBLIC_APP_URL}/join/${boardId}?token=${encodeURIComponent(secret)}`;
}

export function invitePreview(
  result: string,
  boardName: string,
  playerCount: number,
  daysUntilExpiry: number,
): JsonValue {
  return { result, boardName, playerCount, daysUntilExpiry };
}
