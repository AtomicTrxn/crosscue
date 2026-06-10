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
    `select b.id, b.name, b.source_id, b.ranking_mode,
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
