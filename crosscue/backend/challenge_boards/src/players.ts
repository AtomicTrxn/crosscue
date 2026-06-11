// Player identity: bootstrap, restore, profile, avatar, auth, deletion.

import { ApiError, readBody } from "./http.ts";
import { activeMemberCount, eventStatement, transferOwnershipIfDeparting } from "./membership.ts";
import type { Auth, Env, JsonValue, PlayerRow } from "./types.ts";
import { randomSecret, sha256, utcNow } from "./util.ts";
import { dataUrlForAvatar, validateDisplayName, validateRequiredString } from "./validation.ts";

// last_seen_at only needs day-level resolution; refreshing it at most hourly
// avoids one D1 write per authenticated request.
export const lastSeenRefreshMs = 60 * 60 * 1000;

export async function requireAuth(request: Request, env: Env): Promise<Auth> {
  const auth = request.headers.get("authorization") ?? "";
  const token = auth.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) throw new ApiError(401, "unauthorized", "Missing auth token.");
  const tokenHash = await sha256(token);
  const player = await env.DB.prepare(
    `select id, display_name, avatar_kind, avatar_silhouette_look,
            avatar_photo_url, last_seen_at
     from players
     where auth_token_hash = ? and deleted_at is null`,
  )
    .bind(tokenHash)
    .first<PlayerRow & { last_seen_at: string | null }>();
  if (!player) throw new ApiError(401, "unauthorized", "Invalid auth token.");
  const lastSeen = player.last_seen_at ? Date.parse(player.last_seen_at) : 0;
  if (!Number.isFinite(lastSeen) || Date.now() - lastSeen > lastSeenRefreshMs) {
    await env.DB.prepare("update players set last_seen_at = ? where id = ?")
      .bind(utcNow(), player.id)
      .run();
  }
  return { player, tokenHash };
}

export async function getPlayerById(env: Env, playerId: string): Promise<PlayerRow> {
  const player = await env.DB.prepare(
    `select id, display_name, avatar_kind, avatar_silhouette_look,
            avatar_photo_url
     from players
     where id = ? and deleted_at is null`,
  )
    .bind(playerId)
    .first<PlayerRow>();
  if (!player) throw new ApiError(404, "player_not_found", "Player not found.");
  return player;
}

export function serializePlayer(player: PlayerRow, isMe = true): JsonValue {
  return {
    id: player.id,
    displayName: player.display_name,
    isMe,
    avatar: {
      kind: player.avatar_kind,
      silhouetteLook: player.avatar_silhouette_look,
      photoUrl: player.avatar_photo_url,
    },
  };
}

export async function bootstrapPlayer(
  request: Request,
  env: Env,
): Promise<JsonValue> {
  const body = await readBody(request);
  const displayName = validateDisplayName(
    typeof body.displayName === "string" ? body.displayName : "Player",
  );
  const playerId = crypto.randomUUID();
  const token = randomSecret();
  const tokenHash = await sha256(token);
  const recoverySecret = randomSecret();
  const recoveryHash = await sha256(recoverySecret);
  const now = utcNow();

  await env.DB.prepare(
    `insert into players (
      id, display_name, auth_token_hash, recovery_secret_hash,
      created_at, last_seen_at
    ) values (?, ?, ?, ?, ?, ?)`,
  )
    .bind(playerId, displayName, tokenHash, recoveryHash, now, now)
    .run();

  const player = await getPlayerById(env, playerId);
  return {
    player: serializePlayer(player),
    authToken: token,
    recoverySecret,
  };
}

export async function restorePlayer(
  request: Request,
  env: Env,
): Promise<JsonValue> {
  const body = await readBody(request);
  const playerId = validateRequiredString(body.playerId, "restore_failed", 80);
  const recoverySecret = validateRequiredString(
    body.recoverySecret,
    "restore_failed",
    200,
  );
  const recoveryHash = await sha256(recoverySecret);
  const match = await env.DB.prepare(
    `select id from players
     where id = ? and recovery_secret_hash = ? and deleted_at is null`,
  )
    .bind(playerId, recoveryHash)
    .first<{ id: string }>();
  if (!match) {
    throw new ApiError(
      401,
      "restore_failed",
      "Could not restore this player.",
    );
  }

  // Issue a fresh auth token and invalidate the previous one.
  const token = randomSecret();
  const tokenHash = await sha256(token);
  const now = utcNow();
  await env.DB.prepare(
    "update players set auth_token_hash = ?, last_seen_at = ? where id = ?",
  )
    .bind(tokenHash, now, playerId)
    .run();

  const player = await getPlayerById(env, playerId);
  return { player: serializePlayer(player), authToken: token };
}

export async function rotateRecovery(env: Env, auth: Auth): Promise<JsonValue> {
  const recoverySecret = randomSecret();
  const recoveryHash = await sha256(recoverySecret);
  const now = utcNow();
  await env.DB.prepare(
    `update players
     set recovery_secret_hash = ?, recovery_secret_rotated_at = ?
     where id = ?`,
  )
    .bind(recoveryHash, now, auth.player.id)
    .run();
  return { recoverySecret, rotatedAt: now };
}

export async function deletePlayer(env: Env, auth: Auth): Promise<JsonValue> {
  const playerId = auth.player.id;
  const now = utcNow();

  // Leave every active board, recording events and emptying boards as we go.
  const activeBoards = await env.DB.prepare(
    "select board_id from memberships where player_id = ? and left_at is null",
  )
    .bind(playerId)
    .all<{ board_id: string }>();

  const leaveStatements: D1PreparedStatement[] = [];
  for (const { board_id } of activeBoards.results ?? []) {
    leaveStatements.push(
      env.DB.prepare(
        `update memberships
         set left_at = ?, membership_state = 'left'
         where board_id = ? and player_id = ? and left_at is null`,
      ).bind(now, board_id, playerId),
      eventStatement(env, board_id, playerId, "leave", now),
    );
  }
  if (leaveStatements.length > 0) {
    await env.DB.batch(leaveStatements);
  }

  // Auto-delete any board left with no remaining active members; otherwise
  // pass ownership down if the departing player owned the board.
  for (const { board_id } of activeBoards.results ?? []) {
    if ((await activeMemberCount(env, board_id)) === 0) {
      await env.DB.prepare("update boards set deleted_at = ? where id = ?")
        .bind(now, board_id)
        .run();
    } else {
      await transferOwnershipIfDeparting(env, board_id, playerId, now);
    }
  }

  // Remove the player's solve results and anonymize residual participation data.
  await env.DB.batch([
    env.DB.prepare("delete from challenge_results where player_id = ?").bind(
      playerId,
    ),
    env.DB.prepare(
      "update memberships set display_name = 'Deleted' where player_id = ?",
    ).bind(playerId),
    env.DB.prepare(
      `update players
       set deleted_at = ?, display_name = 'Deleted',
           auth_token_hash = '', recovery_secret_hash = null,
           avatar_photo_url = null
       where id = ?`,
    ).bind(now, playerId),
  ]);

  return { ok: true };
}

export async function updatePlayer(
  request: Request,
  env: Env,
  auth: Auth,
): Promise<JsonValue> {
  const body = await readBody(request);
  const displayName = validateDisplayName(body.displayName);
  const now = utcNow();
  await env.DB.batch([
    env.DB.prepare(
      "update players set display_name = ?, last_seen_at = ? where id = ?",
    ).bind(displayName, now, auth.player.id),
    env.DB.prepare(
      `update memberships
       set display_name = ?
       where player_id = ? and left_at is null`,
    ).bind(displayName, auth.player.id),
  ]);
  const player = await getPlayerById(env, auth.player.id);
  return { player: serializePlayer(player) };
}

export async function updateAvatar(
  request: Request,
  env: Env,
  auth: Auth,
): Promise<JsonValue> {
  const body = await readBody(request);
  const kind =
    body.kind === "photo"
      ? "photo"
      : body.kind === "silhouette"
        ? "silhouette"
        : "initials";
  const look =
    typeof body.silhouetteLook === "number"
      ? Math.min(10, Math.max(1, Math.trunc(body.silhouetteLook)))
      : 1;
  const photoUrl =
    kind === "photo" && typeof body.photoPngBase64 === "string"
      ? dataUrlForAvatar(body.photoPngBase64)
      : null;
  await env.DB.prepare(
    `update players
     set avatar_kind = ?, avatar_silhouette_look = ?, avatar_photo_url = ?
     where id = ?`,
  )
    .bind(kind, look, photoUrl, auth.player.id)
    .run();
  const player = await getPlayerById(env, auth.player.id);
  return { player: serializePlayer(player) };
}
