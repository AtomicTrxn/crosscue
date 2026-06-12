// Challenge Boards Worker — request routing and the scheduled retention job.
// Handlers live in feature modules: players, boards, results, leaderboards,
// membership, retention; shared plumbing in http/util/validation/constants.

import {
  createBoard,
  getBoardDetail,
  joinInvite,
  leaveBoard,
  listBoards,
  previewInvite,
  regenerateInvite,
  removeMember,
} from "./boards.ts";
import {
  ApiError,
  clientIp,
  corsHeaders,
  enforceMinClient,
  enforceRateLimit,
  json,
  problem,
} from "./http.ts";
import {
  bootstrapPlayer,
  deletePlayer,
  requireAuth,
  restorePlayer,
  rotateRecovery,
  serializePlayer,
  updateAvatar,
  updatePlayer,
} from "./players.ts";
import { submitResult } from "./results.ts";
import { purgeOldBoardEvents } from "./retention.ts";
import type { Env } from "./types.ts";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    const requestId =
      request.headers.get("x-request-id") ?? crypto.randomUUID();
    try {
      // Force-upgrade lever (#256) — gates every route, including identity
      // creation, when MIN_SUPPORTED_CLIENT is configured.
      enforceMinClient(request, env.MIN_SUPPORTED_CLIENT);

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

      const removeMatch = url.pathname.match(
        /^\/boards\/([^/]+)\/members\/([^/]+)$/,
      );
      if (request.method === "DELETE" && removeMatch) {
        await enforceRateLimit(env.RL_WRITE, auth.player.id);
        return json(
          await removeMember(env, auth, removeMatch[1], removeMatch[2]),
          requestId,
        );
      }

      const leaveMatch = url.pathname.match(/^\/boards\/([^/]+)\/leave$/);
      if (request.method === "POST" && leaveMatch) {
        return json(await leaveBoard(env, auth, leaveMatch[1]), requestId);
      }

      const regenMatch = url.pathname.match(
        /^\/boards\/([^/]+)\/invite\/regenerate$/,
      );
      if (request.method === "POST" && regenMatch) {
        await enforceRateLimit(env.RL_WRITE, auth.player.id);
        return json(
          await regenerateInvite(env, auth, regenMatch[1]),
          requestId,
        );
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
