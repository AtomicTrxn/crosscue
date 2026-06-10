// Request-payload validation and content-safety checks.

import { ApiError } from "./http.ts";
import type { RankingMode } from "./types.ts";
import { dateOnly } from "./util.ts";

export function validateDisplayName(raw: unknown): string {
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

// Reserved handles that would impersonate the app/staff, and a starter
// profanity/slur blocklist. This list is intentionally small and meant to be
// maintained; there is no platform API that makes gaming-handle safety
// automatic, so the server owns this check (clients must not be trusted).
export const reservedDisplayNames = new Set([
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

export const blockedNameFragments = [
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

/// Normalizes a candidate name to defeat common evasions (case, separators,
/// and leetspeak) before checking the reserved and blocked lists.
export function isUnsafeDisplayName(value: string): boolean {
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

export function validateBoardName(raw: unknown): string {
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

export function validateRequiredString(
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

export function validateIsoDateTime(raw: unknown, code: string): string {
  if (typeof raw !== "string") {
    throw new ApiError(400, code, "Expected an ISO date-time.");
  }
  const date = new Date(raw);
  if (!Number.isFinite(date.getTime())) {
    throw new ApiError(400, code, "Expected an ISO date-time.");
  }
  return date.toISOString();
}

export function validateDateOnly(raw: string, code: string): string {
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

export function validatePositiveInteger(raw: unknown, code: string): number {
  if (typeof raw !== "number" || !Number.isFinite(raw) || raw < 0) {
    throw new ApiError(400, code, "Expected a positive integer.");
  }
  return Math.trunc(raw);
}

export function validateCompletionType(raw: unknown): string {
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

export function validateRankingMode(raw: unknown): RankingMode {
  if (
    raw === "fastest_time" ||
    raw === "average_time" ||
    raw === "total_time"
  ) {
    return raw;
  }
  return "average_time";
}

export const pngMagicBytes = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

export function dataUrlForAvatar(rawBase64: string): string {
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

export function parseInviteLink(raw: unknown): { boardId: string; token: string } {
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
