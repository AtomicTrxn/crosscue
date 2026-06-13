// R2-backed avatar photo storage (#268 PR 2).
//
// When the AVATARS bucket is bound, photo uploads are stored in R2 under an
// immutable content-addressed key and served back by reference via a public
// GET route — replacing the inline `data:` URLs that otherwise live in D1 and
// bloat every leaderboard payload. The binding is optional: with no bucket
// (local/test/not-yet-provisioned) the caller falls back to data URLs, so this
// ships inert until the bucket exists. Existing data-URL rows keep working
// forever; a photo migrates to R2 on the player's next avatar change.

import { corsHeaders } from "./http.ts";
import { decodeAvatarPng } from "./validation.ts";

const AVATAR_PREFIX = "avatars/";

function playerPrefix(playerId: string): string {
  return `${AVATAR_PREFIX}${playerId}/`;
}

async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Validates + stores a PNG avatar in R2 under an immutable, content-addressed
 * key (`avatars/<playerId>/<sha256>.png`), removes the player's previous
 * object(s), and returns the public URL the Worker serves it from. The URL is
 * built from the request origin, so it always points back at whatever host the
 * client reached this Worker on (workers.dev today, api.crosscue.app later).
 * Throws the same `400 invalid_avatar` / `413 avatar_too_large` as the
 * data-URL path on bad input.
 */
export async function storeAvatarPhoto(
  bucket: R2Bucket,
  request: Request,
  playerId: string,
  rawBase64: string,
): Promise<string> {
  const bytes = decodeAvatarPng(rawBase64);
  const hash = await sha256Hex(bytes);
  const key = `${playerPrefix(playerId)}${hash}.png`;

  await bucket.put(key, bytes, {
    httpMetadata: { contentType: "image/png" },
  });

  // Content-addressed keys never collide, so anything but the new key is a
  // superseded upload — drop it. Done after the put so there's never a window
  // with no object.
  await deleteAvatarObjects(bucket, playerId, key);

  return `${new URL(request.url).origin}/${key}`;
}

/** Deletes every stored avatar object for a player, except [keepKey]. */
export async function deleteAvatarObjects(
  bucket: R2Bucket,
  playerId: string,
  keepKey?: string,
): Promise<void> {
  const listed = await bucket.list({ prefix: playerPrefix(playerId) });
  const staleKeys = listed.objects
    .map((o) => o.key)
    .filter((k) => k !== keepKey);
  if (staleKeys.length > 0) {
    await bucket.delete(staleKeys);
  }
}

/**
 * Public, unauthenticated avatar read. Returns null for any non-avatar path so
 * the router falls through. Streams the object from R2 with a one-year
 * immutable cache — safe because keys are content-hashed, so a given URL's
 * bytes never change. 404s when the bucket is unbound or the object is missing.
 */
export async function serveAvatar(
  bucket: R2Bucket | undefined,
  pathname: string,
): Promise<Response | null> {
  const match = pathname.match(/^\/(avatars\/[^/]+\/[A-Fa-f0-9]+\.png)$/u);
  if (!match) return null;

  const notFound = () =>
    new Response("Not found", { status: 404, headers: corsHeaders });
  if (!bucket) return notFound();

  const object = await bucket.get(match[1]);
  if (!object) return notFound();

  const headers = new Headers(corsHeaders);
  object.writeHttpMetadata(headers);
  headers.set("content-type", "image/png");
  headers.set("cache-control", "public, max-age=31536000, immutable");
  headers.set("etag", object.httpEtag);
  return new Response(object.body, { status: 200, headers });
}
