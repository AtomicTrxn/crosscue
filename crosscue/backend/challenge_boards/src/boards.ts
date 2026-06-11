// Board lifecycle and invite flows.

import { defaultSourceId, inviteExpiryDays, maxBoardsPerPlayer, maxPlayersPerBoard } from "./constants.ts";
import { ApiError, readBody } from "./http.ts";
import { boardLeaderboard, boardLeaderboards, lifetimeStats, serializeBoardSummary, serializeLeaderboardEntry } from "./leaderboards.ts";
import { activeBoardCount, activeMemberCount, eventStatement, invitePreview, inviteUrl, isActiveMember, requireActiveBoardMember, transferOwnershipIfDeparting, verifyInvite } from "./membership.ts";
import type { Auth, BoardRow, Env, JsonValue } from "./types.ts";
import { addDays, daysUntil, randomSecret, sha256, utcNow } from "./util.ts";
import { parseInviteLink, validateBoardName, validateRankingMode } from "./validation.ts";

export async function listBoards(env: Env, auth: Auth): Promise<JsonValue> {
  const boards = await env.DB.prepare(
    `select b.id, b.name, b.source_id, b.ranking_mode, b.owner_player_id,
            b.invite_expires_at, b.invite_version, count(active.player_id) as player_count
     from boards b
     join memberships mine on mine.board_id = b.id
       and mine.player_id = ? and mine.left_at is null
     left join memberships active on active.board_id = b.id
       and active.left_at is null
     where b.deleted_at is null
     group by b.id
     order by mine.joined_at desc`,
  )
    .bind(auth.player.id)
    .all<BoardRow>();

  const weeklyByBoard = await boardLeaderboards(env, boards.results, "weekly");
  const summaries = boards.results.map((board) => {
    const weekly = weeklyByBoard.get(board.id) ?? [];
    const mine = weekly.find((entry) => entry.player.id === auth.player.id);
    return serializeBoardSummary(board, mine);
  });

  return {
    boards: summaries,
    lifetime: await lifetimeStats(env, auth.player.id),
  };
}

export async function createBoard(
  request: Request,
  env: Env,
  auth: Auth,
): Promise<JsonValue> {
  const activeCount = await activeBoardCount(env, auth.player.id);
  if (activeCount >= maxBoardsPerPlayer) {
    throw new ApiError(
      409,
      "board_limit_reached",
      "You are already in 5 active boards.",
    );
  }

  const body = await readBody(request);
  const name = validateBoardName(body.name);
  const rankingMode = validateRankingMode(body.rankingMode);
  const boardId = crypto.randomUUID();
  const inviteSecret = randomSecret();
  const inviteHash = await sha256(inviteSecret);
  const now = utcNow();
  const expires = addDays(now, inviteExpiryDays);

  await env.DB.batch([
    env.DB.prepare(
      `insert into boards (
        id, name, source_id, ranking_mode, invite_code_hash, invite_expires_at,
        invite_rotated_at, invite_rotated_by_player_id, created_by_player_id,
        owner_player_id, created_at
      ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(
      boardId,
      name,
      defaultSourceId,
      rankingMode,
      inviteHash,
      expires,
      now,
      auth.player.id,
      auth.player.id,
      auth.player.id,
      now,
    ),
    env.DB.prepare(
      `insert into memberships (
        board_id, player_id, display_name, joined_at
      ) values (?, ?, ?, ?)`,
    ).bind(boardId, auth.player.id, auth.player.display_name, now),
    eventStatement(env, boardId, auth.player.id, "board_create", now),
  ]);

  return {
    board: serializeBoardSummary(
      {
        id: boardId,
        name,
        source_id: defaultSourceId,
        ranking_mode: rankingMode,
        invite_expires_at: expires,
        invite_version: 1,
        owner_player_id: auth.player.id,
        player_count: 1,
      },
    ),
    inviteLink: inviteUrl(env, boardId, inviteSecret),
  };
}

export async function getBoardDetail(
  env: Env,
  auth: Auth,
  boardId: string,
): Promise<JsonValue> {
  const board = await requireActiveBoardMember(env, auth.player.id, boardId);
  const weekly = await boardLeaderboard(env, board, "weekly");
  const lifetime = await boardLeaderboard(env, board, "lifetime");
  const mine = weekly.find((entry) => entry.player.id === auth.player.id);

  return {
    board: serializeBoardSummary(board, mine),
    weekly: weekly.map((entry) =>
      serializeLeaderboardEntry(entry, auth.player.id),
    ),
    lifetime: lifetime.map((entry) =>
      serializeLeaderboardEntry(entry, auth.player.id),
    ),
  };
}

export async function previewInvite(
  request: Request,
  env: Env,
  auth: Auth,
): Promise<JsonValue> {
  const body = await readBody(request);
  const invite = parseInviteLink(body.inviteLink);
  const board = await env.DB.prepare(
    `select id, name, source_id, ranking_mode, invite_expires_at,
            invite_version, invite_code_hash, deleted_at
     from boards
     where id = ?`,
  )
    .bind(invite.boardId)
    .first<BoardRow & { invite_code_hash: string }>();
  if (!board || board.deleted_at || !board.invite_expires_at) {
    return { invite: invitePreview("boardDeleted", "Board deleted", 0, 0) };
  }
  // Members may see their own board regardless of the link's validity.
  if (await isActiveMember(env, auth.player.id, board.id)) {
    return {
      invite: invitePreview(
        "alreadyMember",
        board.name,
        await activeMemberCount(env, board.id),
        daysUntil(board.invite_expires_at),
      ),
    };
  }
  // Verify the secret before disclosing anything else about the board: a
  // rotated or guessed link must not reveal the current name or member count.
  const tokenMatches = (await sha256(invite.token)) === board.invite_code_hash;
  if (!tokenMatches) {
    return { invite: invitePreview("invalidOrExpired", "", 0, 0) };
  }
  // An expired-but-genuine link may still show the name: the inviter shared it.
  if (new Date(board.invite_expires_at).getTime() < Date.now()) {
    return { invite: invitePreview("invalidOrExpired", board.name, 0, 0) };
  }
  if (await activeBoardCount(env, auth.player.id) >= maxBoardsPerPlayer) {
    return {
      invite: invitePreview(
        "playerLimitReached",
        board.name,
        await activeMemberCount(env, board.id),
        daysUntil(board.invite_expires_at),
      ),
    };
  }
  const memberCount = await activeMemberCount(env, board.id);
  if (memberCount >= maxPlayersPerBoard) {
    return {
      invite: invitePreview(
        "boardFull",
        board.name,
        memberCount,
        daysUntil(board.invite_expires_at),
      ),
    };
  }
  return {
    invite: invitePreview(
      "valid",
      board.name,
      memberCount,
      daysUntil(board.invite_expires_at),
    ),
  };
}

export async function joinInvite(
  request: Request,
  env: Env,
  auth: Auth,
): Promise<JsonValue> {
  const body = await readBody(request);
  const invite = parseInviteLink(body.inviteLink);
  const valid = await verifyInvite(env, invite.boardId, invite.token);
  if (!valid) {
    throw new ApiError(410, "invalid_or_expired_invite", "Invite unavailable.");
  }
  if (await isActiveMember(env, auth.player.id, invite.boardId)) {
    const detail = await getBoardDetail(env, auth, invite.boardId);
    return { board: (detail as { board: JsonValue }).board };
  }
  if (await activeBoardCount(env, auth.player.id) >= maxBoardsPerPlayer) {
    throw new ApiError(409, "board_limit_reached", "Leave a board to join.");
  }
  const memberCount = await activeMemberCount(env, invite.boardId);
  if (memberCount >= maxPlayersPerBoard) {
    throw new ApiError(409, "board_full", "This board is full.");
  }

  const board = await env.DB.prepare(
    `select id, name, source_id, ranking_mode, owner_player_id,
            invite_expires_at, invite_version
     from boards
     where id = ? and deleted_at is null`,
  )
    .bind(invite.boardId)
    .first<BoardRow>();
  if (!board) {
    throw new ApiError(404, "board_deleted", "This board no longer exists.");
  }

  const now = utcNow();
  await env.DB.batch([
    env.DB.prepare(
      `insert into memberships (
        board_id, player_id, display_name, joined_at, left_at, membership_state
      ) values (?, ?, ?, ?, null, 'active')
      on conflict(board_id, player_id) do update set
        display_name = excluded.display_name,
        joined_at = excluded.joined_at,
        left_at = null,
        membership_state = 'active'`,
    ).bind(invite.boardId, auth.player.id, auth.player.display_name, now),
    eventStatement(env, invite.boardId, auth.player.id, "join", now),
  ]);

  return {
    board: serializeBoardSummary(
      { ...board, player_count: memberCount + 1 },
    ),
  };
}

export async function leaveBoard(
  env: Env,
  auth: Auth,
  boardId: string,
): Promise<JsonValue> {
  await requireActiveBoardMember(env, auth.player.id, boardId);
  const now = utcNow();
  await env.DB.batch([
    env.DB.prepare(
      `update memberships
       set left_at = ?, membership_state = 'left'
       where board_id = ? and player_id = ? and left_at is null`,
    ).bind(now, boardId, auth.player.id),
    eventStatement(env, boardId, auth.player.id, "leave", now),
  ]);

  const remaining = await activeMemberCount(env, boardId);
  if (remaining === 0) {
    await env.DB.prepare("update boards set deleted_at = ? where id = ?")
      .bind(now, boardId)
      .run();
  } else {
    await transferOwnershipIfDeparting(env, boardId, auth.player.id, now);
  }

  return { ok: true, boardDeleted: remaining === 0 };
}

// Owner-only. Removal mirrors leaving for the target: results rows are kept,
// the membership is closed (state 'removed' for the audit trail). A removed
// player can rejoin with a still-valid invite link; the owner's lockout tool
// is invite regeneration.
export async function removeMember(
  env: Env,
  auth: Auth,
  boardId: string,
  targetPlayerId: string,
): Promise<JsonValue> {
  const board = await requireActiveBoardMember(env, auth.player.id, boardId);
  if (board.owner_player_id !== auth.player.id) {
    throw new ApiError(
      403,
      "not_owner",
      "Only the board owner can remove players.",
    );
  }
  if (targetPlayerId === auth.player.id) {
    throw new ApiError(
      400,
      "cannot_remove_self",
      "Leave the board instead of removing yourself.",
    );
  }
  if (!(await isActiveMember(env, targetPlayerId, boardId))) {
    throw new ApiError(404, "member_not_found", "Player is not on this board.");
  }

  const now = utcNow();
  await env.DB.batch([
    env.DB.prepare(
      `update memberships
       set left_at = ?, membership_state = 'removed'
       where board_id = ? and player_id = ? and left_at is null`,
    ).bind(now, boardId, targetPlayerId),
    eventStatement(env, boardId, targetPlayerId, "member_removed", now),
  ]);

  return { ok: true };
}

export async function regenerateInvite(
  env: Env,
  auth: Auth,
  boardId: string,
): Promise<JsonValue> {
  const board = await requireActiveBoardMember(env, auth.player.id, boardId);
  const secret = randomSecret();
  const hash = await sha256(secret);
  const now = utcNow();
  const expires = addDays(now, inviteExpiryDays);
  await env.DB.batch([
    env.DB.prepare(
      `update boards
       set invite_code_hash = ?, invite_version = invite_version + 1,
           invite_expires_at = ?, invite_rotated_at = ?,
           invite_rotated_by_player_id = ?
       where id = ?`,
    ).bind(hash, expires, now, auth.player.id, boardId),
    eventStatement(env, boardId, auth.player.id, "invite_regenerate", now),
  ]);
  return { inviteLink: inviteUrl(env, board.id, secret), expiresAt: expires };
}
