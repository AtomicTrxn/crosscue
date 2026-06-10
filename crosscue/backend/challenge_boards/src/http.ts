// HTTP plumbing: responses, errors, body parsing, rate limiting.

import type { JsonValue, RateLimiter } from "./types.ts";

export const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,POST,PATCH,DELETE,OPTIONS",
  "access-control-allow-headers": "authorization,content-type,x-request-id",
};

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export function json(body: JsonValue, requestId: string, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "content-type": "application/json",
      "x-request-id": requestId,
    },
  });
}

export function problem(
  code: string,
  message: string,
  status: number,
  requestId: string,
): Response {
  return json({ error: { code, message, requestId } }, requestId, status);
}

export async function readBody(request: Request): Promise<Record<string, unknown>> {
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

export function clientIp(request: Request): string {
  return request.headers.get("cf-connecting-ip") ?? "unknown";
}

// Abuse-dampening only. Caps (5 boards/player, 20 players/board) are enforced
// with check-then-insert reads, so concurrent joins can briefly overshoot by
// one — an accepted v1 trade-off (D1 has no row locking inside a request).
// Rate limiting just slows brute-force/spam.

// Abuse-dampening only. Caps (5 boards/player, 20 players/board) are enforced
// with check-then-insert reads, so concurrent joins can briefly overshoot by
// one — an accepted v1 trade-off (D1 has no row locking inside a request).
// Rate limiting just slows brute-force/spam.
export async function enforceRateLimit(
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
