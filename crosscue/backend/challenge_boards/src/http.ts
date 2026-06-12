// HTTP plumbing: responses, errors, body parsing, rate limiting.

import type { JsonValue, RateLimiter } from "./types.ts";

export const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,POST,PATCH,DELETE,OPTIONS",
  "access-control-allow-headers":
    "authorization,content-type,x-request-id,x-crosscue-client",
};

/** Request header carrying the client identity: `<platform>/<semver>`. */
export const clientHeader = "x-crosscue-client";

function parseSemver(value: string): [number, number, number] | null {
  const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(value);
  if (!match) return null;
  return [Number(match[1]), Number(match[2]), Number(match[3])];
}

function semverAtLeast(
  client: [number, number, number],
  min: [number, number, number],
): boolean {
  for (let i = 0; i < 3; i++) {
    if (client[i] !== min[i]) return client[i] > min[i];
  }
  return true;
}

// Force-upgrade lever (#256). When MIN_SUPPORTED_CLIENT is set, requests
// whose X-Crosscue-Client semver is missing, unparsable, or lower than the
// minimum are rejected with a structured 426 client_too_old. Unset means no
// enforcement, and a malformed minimum is ignored rather than taking the
// API down.
export function enforceMinClient(
  request: Request,
  minSupportedClient: string | undefined,
): void {
  if (!minSupportedClient) return;
  const min = parseSemver(minSupportedClient);
  if (!min) return;
  const value = request.headers.get(clientHeader) ?? "";
  const client = parseSemver(value.split("/")[1] ?? "");
  if (client === null || !semverAtLeast(client, min)) {
    throw new ApiError(
      426,
      "client_too_old",
      "This version of Crosscue is no longer supported by Challenge Boards. Please update the app.",
    );
  }
}

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
