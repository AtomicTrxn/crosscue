export interface Env {
  DB: D1Database;
  PUBLIC_APP_URL: string;
  APP_ENV: string;
  // Cloudflare Rate Limiting bindings. Optional so local/test runs without the
  // bindings configured skip limiting rather than crashing.
  RL_IDENTITY?: RateLimiter;
  RL_WRITE?: RateLimiter;
}

interface RateLimiter {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}

type JsonValue =
  | null
  | boolean
  | number
  | string
  | JsonValue[]
  | { [key: string]: JsonValue };

type PlayerRow = {
  id: string;
  display_name: string;
  avatar_kind: string;
  avatar_silhouette_look: number;
  avatar_photo_url: string | null;
};

type BoardRow = {
  id: string;
  name: string;
  source_id: string;
  ranking_mode?: RankingMode;
  invite_expires_at: string;
  invite_version: number;
  player_count?: number;
  deleted_at?: string | null;
};

type RankingMode = "fastest_time" | "average_time" | "total_time";

type Auth = {
  player: PlayerRow;
  tokenHash: string;
};

type LeaderboardRow = {
  rank?: number;
  player: PlayerRow;
  cleanSolves: number;
  avgCleanMs: number | null;
  bestCleanMs: number | null;
  totalCleanMs: number | null;
  weeksCounted: number;
  submittedCount: number;
  assistedCount: number;
};

const maxBoardsPerPlayer = 5;
const maxPlayersPerBoard = 20;
const inviteExpiryDays = 30;
const defaultSourceId = "crosshare_daily_mini";
// Honor-system trust floor (#228): no human solves a Daily Mini this fast, so
// anything below it is a client bug or a trivially faked time.
const minPlausibleElapsedMs = 3000;

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,POST,PATCH,DELETE,OPTIONS",
  "access-control-allow-headers": "authorization,content-type,x-request-id",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    const requestId =
      request.headers.get("x-request-id") ?? crypto.randomUUID();
    try {
      const url = new URL(request.url);
      const route = `${request.method} ${url.pathname}`;

      if (route === "POST /players/bootstrap") {
        await enforceRateLimit(env.RL_IDENTITY, clientIp(request));
        return json(await bootstrapPlayer(request, env), requestId);
      }
      if (route === "POST /players/restore") {
        await enforceRateLimit(env.RL_IDENTITY, clientIp(request));
        return json(await restorePlayer(request, env), requestId);
      }

      const auth = await requireAuth(request, env);

      if (route === "POST /players/recovery/rotate") {
        return json(await rotateRecovery(env, auth), requestId);
      }
      if (route === "DELETE /players/me") {
        return json(await deletePlayer(env, auth), requestId);
      }

      if (route === "GET /players/me") {
        return json({ player: serializePlayer(auth.player) }, requestId);
      }
      if (route === "PATCH /players/me") {
        return json(await updatePlayer(request, env, auth), requestId);
      }
      if (route === "POST /players/me/avatar") {
        return json(await updateAvatar(request, env, auth), requestId);
      }
      if (route === "GET /boards") {
        return json(await listBoards(env, auth), requestId);
      }
      if (route === "POST /boards") {
        return json(await createBoard(request, env, auth), requestId, 201);
      }
      if (route === "POST /invites/preview") {
        return json(await previewInvite(request, env, auth), requestId);
      }
      if (route === "POST /invites/join") {
        await enforceRateLimit(env.RL_WRITE, auth.player.id);
        return json(await joinInvite(request, env, auth), requestId);
      }
      if (route === "POST /results") {
        await enforceRateLimit(env.RL_WRITE, auth.player.id);
        return json(await submitResult(request, env, auth), requestId, 202);
      }

      const boardMatch = url.pathname.match(/^\/boards\/([^/]+)$/);
      if (request.method === "GET" && boardMatch) {
        return json(await getBoardDetail(env, auth, boardMatch[1]), requestId);
      }

      const leaveMatch = url.pathname.match(/^\/boards\/([^/]+)\/leave$/);
      if (request.method === "POST" && leaveMatch) {
        return json(await leaveBoard(env, auth, leaveMatch[1]), requestId);
      }

      const inviteMatch = url.pathname.match(/^\/boards\/([^/]+)\/invite$/);
      if (request.method === "GET" && inviteMatch) {
        return json(await getInviteLink(env, auth, inviteMatch[1]), requestId);
      }

      const regenMatch = url.pathname.match(
        /^\/boards\/([^/]+)\/invite\/regenerate$/,
      );
      if (request.method === "POST" && regenMatch) {
        await enforceRateLimit(env.RL_WRITE, auth.player.id);
        return json(await regenerateInvite(env, auth, regenMatch[1]), requestId);
      }

      return problem("not_found", "Route not found.", 404, requestId);
    } catch (error) {
      if (error instanceof ApiError) {
        return problem(error.code, error.message, error.status, requestId);
      }
      console.error(JSON.stringify({ requestId, error: String(error) }));
      return problem("internal_error", "Something went wrong.", 500, requestId);
    }
  },

  async scheduled(
    _controller: ScheduledController,
    env: Env,
    _ctx: ExecutionContext,
  ): Promise<void> {
    const deleted = await purgeOldBoardEvents(env);
    console.log(JSON.stringify({ job: "purge_board_events", deleted }));
  },
};

const boardEventsRetentionDays = 14;
const purgeChunkSize = 500;

// Daily retention for the audit-only board_events table. challenge_results is
// intentionally retained because lifetime leaderboards are computed live from it
// (no player_board_stats rollover in v1); purging it would shrink lifetime stats.
async function purgeOldBoardEvents(env: Env): Promise<number> {
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

async function bootstrapPlayer(
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

async function restorePlayer(
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

async function rotateRecovery(env: Env, auth: Auth): Promise<JsonValue> {
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

async function deletePlayer(env: Env, auth: Auth): Promise<JsonValue> {
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

  // Auto-delete any board left with no remaining active members.
  for (const { board_id } of activeBoards.results ?? []) {
    if ((await activeMemberCount(env, board_id)) === 0) {
      await env.DB.prepare("update boards set deleted_at = ? where id = ?")
        .bind(now, board_id)
        .run();
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

async function updatePlayer(
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

async function updateAvatar(
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
      ? Math.min(3, Math.max(1, Math.trunc(body.silhouetteLook)))
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

async function listBoards(env: Env, auth: Auth): Promise<JsonValue> {
  const boards = await env.DB.prepare(
    `select b.id, b.name, b.source_id, b.ranking_mode,
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

  const summaries = [];
  for (const board of boards.results) {
    const weekly = await boardLeaderboard(env, board, "weekly");
    const mine = weekly.find((entry) => entry.player.id === auth.player.id);
    summaries.push(serializeBoardSummary(board, mine));
  }

  return {
    boards: summaries,
    lifetime: await lifetimeStats(env, auth.player.id),
  };
}

async function createBoard(
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
        created_at
      ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
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
        player_count: 1,
      },
    ),
    inviteLink: inviteUrl(env, boardId, inviteSecret),
  };
}

async function getBoardDetail(
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

async function previewInvite(
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

async function joinInvite(
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
    `select id, name, source_id, ranking_mode, invite_expires_at, invite_version
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

async function submitResult(
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

async function leaveBoard(
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
  }

  return { ok: true, boardDeleted: remaining === 0 };
}

async function getInviteLink(
  env: Env,
  auth: Auth,
  boardId: string,
): Promise<JsonValue> {
  await requireActiveBoardMember(env, auth.player.id, boardId);
  return {
    inviteLink: inviteUrl(env, boardId, "current-secret-not-readable"),
    needsRegeneration: true,
  };
}

async function regenerateInvite(
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

function clientIp(request: Request): string {
  return request.headers.get("cf-connecting-ip") ?? "unknown";
}

// Abuse-dampening only. Caps (5 boards/player, 20 players/board) are enforced
// with check-then-insert reads, so concurrent joins can briefly overshoot by
// one — an accepted v1 trade-off (D1 has no row locking inside a request).
// Rate limiting just slows brute-force/spam.
async function enforceRateLimit(
  limiter: RateLimiter | undefined,
  key: string,
): Promise<void> {
  if (!limiter) return;
  const { success } = await limiter.limit({ key });
  if (!success) {
    throw new ApiError(
      429,
      "rate_limited",
      "Too many requests. Please try again shortly.",
    );
  }
}

// last_seen_at only needs day-level resolution; refreshing it at most hourly
// avoids one D1 write per authenticated request.
const lastSeenRefreshMs = 60 * 60 * 1000;

async function requireAuth(request: Request, env: Env): Promise<Auth> {
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

async function getPlayerById(env: Env, playerId: string): Promise<PlayerRow> {
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

async function requireActiveBoardMember(
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

async function activeBoardCount(env: Env, playerId: string): Promise<number> {
  const row = await env.DB.prepare(
    "select count(*) as count from memberships where player_id = ? and left_at is null",
  )
    .bind(playerId)
    .first<{ count: number }>();
  return Number(row?.count ?? 0);
}

async function activeMemberCount(env: Env, boardId: string): Promise<number> {
  const row = await env.DB.prepare(
    "select count(*) as count from memberships where board_id = ? and left_at is null",
  )
    .bind(boardId)
    .first<{ count: number }>();
  return Number(row?.count ?? 0);
}

async function isActiveMember(
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

async function verifyInvite(
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

async function boardLeaderboard(
  env: Env,
  board: BoardRow,
  mode: "weekly" | "lifetime",
): Promise<LeaderboardRow[]> {
  const week = currentUtcWeekRange();
  const rankingMode = board.ranking_mode ?? "average_time";
  const params =
    mode === "weekly"
      ? [board.id, board.source_id, week.startDate, week.endDate]
      : [board.id, board.source_id];
  const where =
    mode === "weekly"
      ? "and r.published_on >= ? and r.published_on < ?"
      : "";
  const rows = await env.DB.prepare(
    `select p.id, m.display_name, p.avatar_kind, p.avatar_silhouette_look,
            p.avatar_photo_url,
            coalesce(sum(case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then 1 else 0 end), 0) as cleanSolves,
            avg(case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then r.elapsed_ms else null end) as avgCleanMs,
            min(case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then r.elapsed_ms else null end) as bestCleanMs,
            sum(case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then r.elapsed_ms else null end) as totalCleanMs,
            count(r.id) as submittedCount,
            coalesce(sum(case
              when r.id is not null
               and not (r.completion_type = 'clean'
                and r.clean_solve_eligible = 1)
              then 1 else 0 end), 0) as assistedCount,
            count(distinct case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then date(
                r.completed_at,
                '-' || ((cast(strftime('%w', r.completed_at) as integer) + 6) % 7) || ' days'
              )
              else null end) as weeksCounted
     from memberships m
     join players p on p.id = m.player_id
     left join challenge_results r on r.player_id = m.player_id
       and r.source_id = ? ${where}
     where m.board_id = ? and m.left_at is null
     group by p.id, m.display_name, p.avatar_kind, p.avatar_silhouette_look,
              p.avatar_photo_url, m.joined_at
     order by m.joined_at asc`,
  )
    .bind(params[1], ...params.slice(2), params[0])
    .all<PlayerRow & {
      cleanSolves: number;
      avgCleanMs: number | null;
      bestCleanMs: number | null;
      totalCleanMs: number | null;
      weeksCounted: number;
      submittedCount: number;
      assistedCount: number;
    }>();

  const entries: LeaderboardRow[] = rows.results.map((row) => ({
    player: {
      id: row.id,
      display_name: row.display_name,
      avatar_kind: row.avatar_kind,
      avatar_silhouette_look: row.avatar_silhouette_look,
      avatar_photo_url: row.avatar_photo_url,
    },
    cleanSolves: Number(row.cleanSolves ?? 0),
    avgCleanMs: row.avgCleanMs == null ? null : Number(row.avgCleanMs),
    bestCleanMs: row.bestCleanMs == null ? null : Number(row.bestCleanMs),
    totalCleanMs: row.totalCleanMs == null ? null : Number(row.totalCleanMs),
    weeksCounted: Number(row.weeksCounted ?? 0),
    submittedCount: Number(row.submittedCount ?? 0),
    assistedCount: Number(row.assistedCount ?? 0),
  }));

  entries.sort((a, b) => compareLeaderboardRows(a, b, rankingMode));
  entries.forEach((entry, index) => {
    entry.rank = index + 1;
  });
  return entries;
}

async function lifetimeStats(env: Env, playerId: string): Promise<JsonValue> {
  const row = await env.DB.prepare(
    `select count(*) as cleanSolves,
            avg(elapsed_ms) as avgCleanMs,
            min(elapsed_ms) as bestCleanMs,
            count(distinct date(
              completed_at,
              '-' || ((cast(strftime('%w', completed_at) as integer) + 6) % 7) || ' days'
            )) as weeksCounted
     from challenge_results
     where player_id = ?
       and completion_type = 'clean'
       and clean_solve_eligible = 1`,
  )
    .bind(playerId)
    .first<{
      cleanSolves: number;
      avgCleanMs: number | null;
      bestCleanMs: number | null;
      weeksCounted: number;
    }>();

  const cleanSolves = Number(row?.cleanSolves ?? 0);
  return {
    avgClean: formatMs(row?.avgCleanMs ?? null),
    cleanSolves,
    bestClean: formatMs(row?.bestCleanMs ?? null),
    rankingStatus:
      cleanSolves >= 5
        ? `Ranked across ${Number(row?.weeksCounted ?? 0)} UTC weeks`
        : "Solve 5 clean puzzles to unlock lifetime ranking",
    weeksCounted: Number(row?.weeksCounted ?? 0),
  };
}

function compareLeaderboardRows(
  a: LeaderboardRow,
  b: LeaderboardRow,
  rankingMode: RankingMode,
): number {
  if (a.cleanSolves === 0 && b.cleanSolves > 0) return 1;
  if (a.cleanSolves > 0 && b.cleanSolves === 0) return -1;
  const aMetric = rankingMetric(a, rankingMode);
  const bMetric = rankingMetric(b, rankingMode);
  if (aMetric == null && bMetric != null) return 1;
  if (aMetric != null && bMetric == null) return -1;
  if (aMetric != null && bMetric != null && aMetric !== bMetric) {
    return aMetric - bMetric;
  }
  if (b.cleanSolves !== a.cleanSolves) return b.cleanSolves - a.cleanSolves;
  if (b.assistedCount !== a.assistedCount) {
    return b.assistedCount - a.assistedCount;
  }
  return a.player.display_name.localeCompare(b.player.display_name);
}

function rankingMetric(
  entry: LeaderboardRow,
  rankingMode: RankingMode,
): number | null {
  if (entry.cleanSolves === 0) return null;
  if (rankingMode === "fastest_time") return entry.bestCleanMs;
  if (rankingMode === "total_time") return entry.totalCleanMs;
  return entry.avgCleanMs;
}

function serializePlayer(player: PlayerRow, isMe = true): JsonValue {
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

function serializeBoardSummary(
  board: BoardRow,
  standing?: LeaderboardRow,
): JsonValue {
  const count = Number(board.player_count ?? 1);
  return {
    id: board.id,
    name: board.name,
    playerCount: count,
    rankingMode: board.ranking_mode ?? "average_time",
    myWeekly: {
      rank: standing?.rank ?? count,
      outOf: count,
      cleanSolves: standing?.cleanSolves ?? 0,
      avgClean: formatMs(standing?.avgCleanMs ?? null),
      bestClean: formatMs(standing?.bestCleanMs ?? null),
      totalClean: formatMs(standing?.totalCleanMs ?? null),
    },
  };
}

function serializeLeaderboardEntry(
  entry: LeaderboardRow,
  currentPlayerId: string,
): JsonValue {
  return {
    rank: entry.rank ?? 1,
    player: serializePlayer(entry.player, entry.player.id === currentPlayerId),
    cleanSolves: entry.cleanSolves,
    avgClean: formatMs(entry.avgCleanMs),
    bestClean: formatMs(entry.bestCleanMs),
    totalClean: formatMs(entry.totalCleanMs),
    weeksCounted: entry.weeksCounted,
  };
}

function emptyLifetime(): JsonValue {
  return {
    avgClean: "—",
    cleanSolves: 0,
    bestClean: "—",
    rankingStatus: "Solve 5 clean puzzles to unlock lifetime ranking",
    weeksCounted: 0,
  };
}

function invitePreview(
  result: string,
  boardName: string,
  playerCount: number,
  daysUntilExpiry: number,
): JsonValue {
  return { result, boardName, playerCount, daysUntilExpiry };
}

async function readBody(request: Request): Promise<Record<string, unknown>> {
  try {
    const raw = await request.json();
    if (raw && typeof raw === "object" && !Array.isArray(raw)) {
      return raw as Record<string, unknown>;
    }
  } catch {
    // handled below
  }
  throw new ApiError(400, "invalid_json", "Expected a JSON object.");
}

function validateDisplayName(raw: unknown): string {
  if (typeof raw !== "string") {
    throw new ApiError(400, "invalid_display_name", "Display name is required.");
  }
  const value = raw.trim();
  if (value.length === 0) {
    throw new ApiError(400, "invalid_display_name", "Display name is required.");
  }
  if ([...value].length > 10) {
    throw new ApiError(
      400,
      "invalid_display_name",
      "Display name must be 10 characters or fewer.",
    );
  }
  if (/[\u0000-\u001F\u007F]/u.test(raw) || /\s{2,}/u.test(raw)) {
    throw new ApiError(400, "invalid_display_name", "Display name is invalid.");
  }
  if (!/^[A-Za-z0-9 _-]+$/u.test(value)) {
    throw new ApiError(
      400,
      "invalid_display_name",
      "Use letters, numbers, spaces, underscores, or hyphens.",
    );
  }
  if (isUnsafeDisplayName(value)) {
    throw new ApiError(
      400,
      "invalid_display_name",
      "Please choose a different display name.",
    );
  }
  return value;
}

// Reserved handles that would impersonate the app/staff, and a starter
// profanity/slur blocklist. This list is intentionally small and meant to be
// maintained; there is no platform API that makes gaming-handle safety
// automatic, so the server owns this check (clients must not be trusted).
const reservedDisplayNames = new Set([
  "admin",
  "administrator",
  "moderator",
  "mod",
  "crosscue",
  "support",
  "staff",
  "system",
  "official",
  "owner",
  "root",
  "null",
  "undefined",
]);

const blockedNameFragments = [
  "fuck",
  "shit",
  "cunt",
  "bitch",
  "nigger",
  "nigga",
  "faggot",
  "fag",
  "retard",
  "rape",
  "nazi",
];

/// Normalizes a candidate name to defeat common evasions (case, separators,
/// and leetspeak) before checking the reserved and blocked lists.
function isUnsafeDisplayName(value: string): boolean {
  const normalized = value
    .toLowerCase()
    .replaceAll("0", "o")
    .replaceAll("1", "i")
    .replaceAll("3", "e")
    .replaceAll("4", "a")
    .replaceAll("5", "s")
    .replaceAll("7", "t")
    .replaceAll("@", "a")
    .replaceAll("$", "s")
    .replace(/[^a-z]/gu, "");
  if (normalized.length === 0) return false;
  if (reservedDisplayNames.has(normalized)) return true;
  return blockedNameFragments.some((fragment) =>
    normalized.includes(fragment),
  );
}

function validateBoardName(raw: unknown): string {
  if (typeof raw !== "string") {
    throw new ApiError(400, "invalid_board_name", "Board name is required.");
  }
  const value = raw.trim();
  if (value.length === 0 || [...value].length > 30) {
    throw new ApiError(
      400,
      "invalid_board_name",
      "Board name must be 1-30 characters.",
    );
  }
  return value;
}

function validateRequiredString(
  raw: unknown,
  code: string,
  maxLength: number,
): string {
  if (typeof raw !== "string") {
    throw new ApiError(400, code, "Required value is missing.");
  }
  const value = raw.trim();
  if (value.length === 0 || value.length > maxLength) {
    throw new ApiError(400, code, "Required value is invalid.");
  }
  return value;
}

function validateIsoDateTime(raw: unknown, code: string): string {
  if (typeof raw !== "string") {
    throw new ApiError(400, code, "Expected an ISO date-time.");
  }
  const date = new Date(raw);
  if (!Number.isFinite(date.getTime())) {
    throw new ApiError(400, code, "Expected an ISO date-time.");
  }
  return date.toISOString();
}

function validateDateOnly(raw: string, code: string): string {
  // Shape, then a round-trip so impossible dates (2026-13-99, 2026-02-30)
  // are rejected rather than stored and string-compared against week ranges.
  if (!/^\d{4}-\d{2}-\d{2}$/u.test(raw)) {
    throw new ApiError(400, code, "Expected YYYY-MM-DD.");
  }
  const parsed = new Date(`${raw}T00:00:00.000Z`);
  if (!Number.isFinite(parsed.getTime()) || dateOnly(parsed) !== raw) {
    throw new ApiError(400, code, "Expected a real calendar date.");
  }
  return raw;
}

function validatePositiveInteger(raw: unknown, code: string): number {
  if (typeof raw !== "number" || !Number.isFinite(raw) || raw < 0) {
    throw new ApiError(400, code, "Expected a positive integer.");
  }
  return Math.trunc(raw);
}

function validateCompletionType(raw: unknown): string {
  if (
    raw === "clean" ||
    raw === "checked" ||
    raw === "hinted" ||
    raw === "revealed" ||
    raw === "unsolved"
  ) {
    return raw;
  }
  throw new ApiError(400, "invalid_completion_type", "Completion type invalid.");
}

function validateRankingMode(raw: unknown): RankingMode {
  if (
    raw === "fastest_time" ||
    raw === "average_time" ||
    raw === "total_time"
  ) {
    return raw;
  }
  return "average_time";
}

const pngMagicBytes = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

function dataUrlForAvatar(rawBase64: string): string {
  if (rawBase64.length > 500_000) {
    throw new ApiError(
      413,
      "avatar_too_large",
      "Avatar image is too large.",
    );
  }
  if (!/^[A-Za-z0-9+/=]+$/u.test(rawBase64)) {
    throw new ApiError(400, "invalid_avatar", "Avatar image is invalid.");
  }
  // The stored value is served back to every board member as image/png, so
  // require the payload to actually start like one rather than persisting
  // arbitrary bytes.
  let bytes: Uint8Array;
  try {
    bytes = Uint8Array.from(atob(rawBase64), (c) => c.charCodeAt(0));
  } catch {
    throw new ApiError(400, "invalid_avatar", "Avatar image is invalid.");
  }
  if (
    bytes.length < pngMagicBytes.length ||
    pngMagicBytes.some((expected, i) => bytes[i] !== expected)
  ) {
    throw new ApiError(400, "invalid_avatar", "Avatar must be a PNG image.");
  }
  return `data:image/png;base64,${rawBase64}`;
}

function parseInviteLink(raw: unknown): { boardId: string; token: string } {
  if (typeof raw !== "string") {
    throw new ApiError(400, "invalid_invite", "Invite link is required.");
  }
  try {
    const url = new URL(raw);
    const boardId = url.pathname.split("/").filter(Boolean).at(-1);
    const token = url.searchParams.get("token");
    if (!boardId || !token) throw new Error("missing parts");
    return { boardId, token };
  } catch {
    throw new ApiError(400, "invalid_invite", "Invite link is invalid.");
  }
}

function eventStatement(
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

function inviteUrl(env: Env, boardId: string, secret: string): string {
  return `${env.PUBLIC_APP_URL}/join/${boardId}?token=${encodeURIComponent(secret)}`;
}

function utcNow(): string {
  return new Date().toISOString();
}

function addDays(iso: string, days: number): string {
  const date = new Date(iso);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString();
}

function daysUntil(iso: string): number {
  return Math.max(
    0,
    Math.ceil((new Date(iso).getTime() - Date.now()) / 86_400_000),
  );
}

function currentUtcWeekRange(): {
  start: string;
  end: string;
  startDate: string;
  endDate: string;
} {
  const now = new Date();
  const start = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
  const daysSinceMonday = (start.getUTCDay() + 6) % 7;
  start.setUTCDate(start.getUTCDate() - daysSinceMonday);
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 7);
  return {
    start: start.toISOString(),
    end: end.toISOString(),
    startDate: dateOnly(start),
    endDate: dateOnly(end),
  };
}

function dateOnly(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function formatMs(value: number | null | undefined): string {
  if (value == null || !Number.isFinite(value)) return "—";
  const totalSeconds = Math.max(0, Math.round(value / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = String(totalSeconds % 60).padStart(2, "0");
  return `${minutes}:${seconds}`;
}

function randomSecret(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return base64Url(bytes);
}

async function sha256(value: string): Promise<string> {
  const data = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return base64Url(new Uint8Array(digest));
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function json(body: JsonValue, requestId: string, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "content-type": "application/json",
      "x-request-id": requestId,
    },
  });
}

function problem(
  code: string,
  message: string,
  status: number,
  requestId: string,
): Response {
  return json({ error: { code, message, requestId } }, requestId, status);
}

class ApiError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}
