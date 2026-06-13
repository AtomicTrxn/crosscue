import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import test from 'node:test';
import { DatabaseSync } from 'node:sqlite';

import worker from '../src/index.ts';

const apiBase = 'https://challenge.test';

test('invite preview, join, leave, and deleted-board preview flow', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');

  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });
  assert.ok(
    created.inviteLink.startsWith(`${app.env.PUBLIC_APP_URL}/join/`),
    `invite link should be generated on PUBLIC_APP_URL: ${created.inviteLink}`,
  );

  const validPreview = await app.fetchJson('/invites/preview', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: created.inviteLink },
  });
  assert.equal(validPreview.invite.result, 'valid');
  assert.equal(validPreview.invite.playerCount, 1);

  const joined = await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: created.inviteLink },
  });
  assert.equal(joined.board.playerCount, 2);

  const memberPreview = await app.fetchJson('/invites/preview', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: created.inviteLink },
  });
  assert.equal(memberPreview.invite.result, 'alreadyMember');

  await app.fetchJson(`/boards/${created.board.id}/leave`, {
    method: 'POST',
    token: noah.authToken,
  });
  const afterLeave = await app.fetchJson(`/boards/${created.board.id}`, {
    token: maya.authToken,
  });
  assert.equal(afterLeave.board.playerCount, 1);

  const finalLeave = await app.fetchJson(`/boards/${created.board.id}/leave`, {
    method: 'POST',
    token: maya.authToken,
  });
  assert.equal(finalLeave.boardDeleted, true);

  const deletedPreview = await app.fetchJson('/invites/preview', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: created.inviteLink },
  });
  assert.equal(deletedPreview.invite.result, 'boardDeleted');
});

test('result submissions rank clean solves above assisted entries', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: created.inviteLink },
  });

  await app.submitResult(maya.authToken, {
    sourcePuzzleId: '2026-06-05',
    elapsedMs: 90000,
    completionType: 'clean',
    cleanSolveEligible: true,
  });
  await app.submitResult(noah.authToken, {
    sourcePuzzleId: '2026-06-05',
    elapsedMs: 60000,
    completionType: 'checked',
    cleanSolveEligible: false,
  });

  const detail = await app.fetchJson(`/boards/${created.board.id}`, {
    token: maya.authToken,
  });

  assert.equal(detail.weekly[0].player.displayName, 'Maya');
  assert.equal(detail.weekly[0].rank, 1);
  assert.equal(detail.weekly[0].cleanSolves, 1);
  assert.equal(detail.weekly[0].avgClean, '1:30');
  assert.equal(detail.weekly[1].player.displayName, 'Noah');
  assert.equal(detail.weekly[1].cleanSolves, 0);
  assert.equal(detail.board.myWeekly.rank, 1);
  assert.equal(detail.board.myWeekly.cleanSolves, 1);

  const summary = await app.fetchJson('/boards', { token: maya.authToken });
  assert.equal(summary.boards[0].myWeekly.avgClean, '1:30');
  assert.equal(summary.lifetime.cleanSolves, 1);
});

test('weekly rankings use board time mode and published Daily Mini week', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew', rankingMode: 'average_time' },
    status: 201,
  });
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: created.inviteLink },
  });

  await app.submitResult(maya.authToken, {
    sourcePuzzleId: 'last-week',
    publishedOn: previousUtcWeekDateOnly(),
    elapsedMs: 45000,
  });
  await app.submitResult(maya.authToken, {
    sourcePuzzleId: 'current-1',
    publishedOn: currentUtcDateOnly(),
    elapsedMs: 90000,
  });
  await app.submitResult(maya.authToken, {
    sourcePuzzleId: 'current-2',
    publishedOn: currentUtcDateOnly(),
    elapsedMs: 110000,
  });
  await app.submitResult(noah.authToken, {
    sourcePuzzleId: 'current-1',
    publishedOn: currentUtcDateOnly(),
    elapsedMs: 60000,
  });

  const detail = await app.fetchJson(`/boards/${created.board.id}`, {
    token: maya.authToken,
  });

  assert.equal(detail.board.rankingMode, 'average_time');
  assert.equal(detail.weekly[0].player.displayName, 'Noah');
  assert.equal(detail.weekly[0].avgClean, '1:00');
  assert.equal(detail.weekly[1].player.displayName, 'Maya');
  assert.equal(detail.weekly[1].cleanSolves, 2);
  assert.equal(detail.weekly[1].avgClean, '1:40');
  assert.equal(detail.weekly[1].totalClean, '3:20');
});

test('board list ranks each board independently in one pass', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  // Board A: Maya solo. Board B (fastest_time): both players.
  const boardA = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Solo Board' },
    status: 201,
  });
  const boardB = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Race Board', rankingMode: 'fastest_time' },
    status: 201,
  });
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: boardB.inviteLink },
  });

  await app.submitResult(maya.authToken, { elapsedMs: 90000 });
  await app.submitResult(noah.authToken, { elapsedMs: 60000 });

  const summary = await app.fetchJson('/boards', { token: maya.authToken });
  const byName = Object.fromEntries(
    summary.boards.map((b) => [b.name, b]),
  );

  assert.equal(byName['Solo Board'].myWeekly.rank, 1);
  assert.equal(byName['Solo Board'].myWeekly.outOf, 1);
  assert.equal(byName['Race Board'].myWeekly.rank, 2);
  assert.equal(byName['Race Board'].myWeekly.outOf, 2);
  assert.equal(byName['Race Board'].myWeekly.bestClean, '1:30');
});

test('result submissions are idempotent per player source puzzle', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  await app.submitResult(maya.authToken, {
    sourcePuzzleId: '2026-06-05',
    elapsedMs: 100000,
    completionType: 'clean',
    cleanSolveEligible: true,
  });
  await app.submitResult(maya.authToken, {
    sourcePuzzleId: '2026-06-05',
    elapsedMs: 80000,
    completionType: 'clean',
    cleanSolveEligible: true,
  });

  const detail = await app.fetchJson(`/boards/${created.board.id}`, {
    token: maya.authToken,
  });
  assert.equal(detail.weekly[0].cleanSolves, 1);
  assert.equal(detail.weekly[0].avgClean, '1:20');
});

test('non Daily Mini submissions are not accepted', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  const result = await app.submitResult(maya.authToken, {
    sourceId: 'local_import',
    sourcePuzzleId: 'local-puzzle',
    publishedOn: currentUtcDateOnly(),
  });

  assert.equal(result.accepted, false);
  assert.equal(result.reason, 'not_challenge_daily_mini');
});

test('implausibly fast submissions are rejected and not stored', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  const result = await app.submitResult(maya.authToken, { elapsedMs: 2999 });

  assert.equal(result.accepted, false);
  assert.equal(result.reason, 'implausible_elapsed_ms');
  const rows = app.env.DB.db
    .prepare('select count(*) as n from challenge_results where player_id = ?')
    .get(maya.player.id);
  assert.equal(rows.n, 0);

  // The floor boundary itself is accepted.
  const atFloor = await app.submitResult(maya.authToken, { elapsedMs: 3000 });
  assert.equal(atFloor.accepted, true);
});

test('non-clean completions are never clean-ranking eligible', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  // A buggy or dishonest client claims a revealed solve is clean-eligible.
  await app.submitResult(maya.authToken, {
    completionType: 'revealed',
    cleanSolveEligible: true,
  });

  const stored = app.env.DB.db
    .prepare(
      'select clean_solve_eligible from challenge_results where player_id = ?',
    )
    .get(maya.player.id);
  assert.equal(stored.clean_solve_eligible, 0);

  const detail = await app.fetchJson(`/boards/${created.board.id}`, {
    token: maya.authToken,
  });
  assert.equal(detail.weekly[0].cleanSolves, 0);
});

test('rotated invite links reveal no board details on preview', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });
  const staleLink = created.inviteLink;
  await app.fetchJson(`/boards/${created.board.id}/invite/regenerate`, {
    method: 'POST',
    token: maya.authToken,
  });

  const preview = await app.fetchJson('/invites/preview', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: staleLink },
  });

  assert.equal(preview.invite.result, 'invalidOrExpired');
  assert.equal(preview.invite.boardName, '');
  assert.equal(preview.invite.playerCount, 0);
});

test('legacy crosscue.app-hosted invite links are still accepted', async () => {
  // Links are generated on crosscue.pages.dev today, but the apex-host shape
  // must keep working (parseInviteLink is host-agnostic by design).
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });
  const legacyLink = created.inviteLink.replace(
    'https://crosscue.pages.dev/',
    'https://crosscue.app/',
  );
  assert.notEqual(legacyLink, created.inviteLink);

  const preview = await app.fetchJson('/invites/preview', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: legacyLink },
  });
  assert.equal(preview.invite.result, 'valid');

  const joined = await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: legacyLink },
  });
  assert.equal(joined.board.playerCount, 2);
});

test('future-dated and impossible-date submissions are rejected', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  const futureCompleted = await app.submitResult(maya.authToken, {
    completedAt: new Date(Date.now() + 3 * 86_400_000).toISOString(),
  });
  assert.equal(futureCompleted.accepted, false);
  assert.equal(futureCompleted.reason, 'implausible_completed_at');

  const impossibleDate = await app.fetchJson('/results', {
    method: 'POST',
    token: maya.authToken,
    status: 400,
    body: {
      sourceId: 'crosshare_daily_mini',
      sourcePuzzleId: '2026-13-99',
      completedAt: new Date().toISOString(),
      elapsedMs: 90000,
      completionType: 'clean',
      cleanSolveEligible: true,
      publishedOn: '2026-13-99',
    },
  });
  assert.equal(impossibleDate.error.code, 'published_on');
});

test('silhouette looks accept the full preset range and clamp beyond it', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');

  const ten = await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    body: { kind: 'silhouette', silhouetteLook: 10 },
  });
  assert.equal(ten.player.avatar.silhouetteLook, 10);

  const clamped = await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    body: { kind: 'silhouette', silhouetteLook: 11 },
  });
  assert.equal(clamped.player.avatar.silhouetteLook, 10);
});

test('avatar uploads must be PNG bytes', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  // 1x1 transparent PNG.
  const png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8' +
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  const ok = await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    body: { kind: 'photo', photoPngBase64: png },
  });
  assert.equal(ok.player.avatar.kind, 'photo');
  assert.ok(ok.player.avatar.photoUrl.startsWith('data:image/png;base64,'));

  const notPng = Buffer.from('<svg onload=alert(1)>').toString('base64');
  const rejected = await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    status: 400,
    body: { kind: 'photo', photoPngBase64: notPng },
  });
  assert.equal(rejected.error.code, 'invalid_avatar');
});

test('last_seen_at is refreshed at most hourly', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const readLastSeen = () =>
    app.env.DB.db
      .prepare('select last_seen_at from players where id = ?')
      .get(maya.player.id).last_seen_at;

  // Fresh bootstrap: within the refresh window, requests do not write.
  const initial = readLastSeen();
  await app.fetchJson('/players/me', { token: maya.authToken });
  assert.equal(readLastSeen(), initial);

  // Stale value: the next authenticated request refreshes it.
  const stale = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();
  app.env.DB.db
    .prepare('update players set last_seen_at = ? where id = ?')
    .run(stale, maya.player.id);
  await app.fetchJson('/players/me', { token: maya.authToken });
  assert.notEqual(readLastSeen(), stale);
});

test('owner can remove a member; others cannot', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const zoe = await app.bootstrap('Zoe');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });
  for (const t of [noah.authToken, zoe.authToken]) {
    await app.fetchJson('/invites/join', {
      method: 'POST',
      token: t,
      body: { inviteLink: created.inviteLink },
    });
  }
  assert.equal(created.board.ownerPlayerId, maya.player.id);

  // Non-owner cannot remove.
  const denied = await app.fetchJson(
    `/boards/${created.board.id}/members/${zoe.player.id}`,
    { method: 'DELETE', token: noah.authToken, status: 403 },
  );
  assert.equal(denied.error.code, 'not_owner');

  // Owner cannot remove themselves.
  const self = await app.fetchJson(
    `/boards/${created.board.id}/members/${maya.player.id}`,
    { method: 'DELETE', token: maya.authToken, status: 400 },
  );
  assert.equal(self.error.code, 'cannot_remove_self');

  // Owner removes Noah.
  const removed = await app.fetchJson(
    `/boards/${created.board.id}/members/${noah.player.id}`,
    { method: 'DELETE', token: maya.authToken },
  );
  assert.equal(removed.ok, true);

  const state = app.env.DB.db
    .prepare(
      'select membership_state from memberships where board_id = ? and player_id = ?',
    )
    .get(created.board.id, noah.player.id);
  assert.equal(state.membership_state, 'removed');

  // Noah no longer sees the board; the leaderboard no longer lists him.
  await app.fetchJson(`/boards/${created.board.id}`, {
    token: noah.authToken,
    status: 404,
  });
  const detail = await app.fetchJson(`/boards/${created.board.id}`, {
    token: maya.authToken,
  });
  assert.deepEqual(
    detail.weekly.map((e) => e.player.displayName).sort(),
    ['Maya', 'Zoe'],
  );

  // Removing someone who is not an active member 404s.
  const again = await app.fetchJson(
    `/boards/${created.board.id}/members/${noah.player.id}`,
    { method: 'DELETE', token: maya.authToken, status: 404 },
  );
  assert.equal(again.error.code, 'member_not_found');

  // A still-valid invite lets the removed player rejoin.
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: created.inviteLink },
  });
});

test('ownership passes down join order as owners depart', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const zoe = await app.bootstrap('Zoe');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });
  // Distinct joined_at ordering: Noah joins before Zoe.
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: created.inviteLink },
  });
  app.env.DB.db
    .prepare(
      'update memberships set joined_at = ? where board_id = ? and player_id = ?',
    )
    .run('2026-06-09T00:00:00.000Z', created.board.id, noah.player.id);
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: zoe.authToken,
    body: { inviteLink: created.inviteLink },
  });

  // Creator leaves → earliest joiner (Noah) inherits.
  await app.fetchJson(`/boards/${created.board.id}/leave`, {
    method: 'POST',
    token: maya.authToken,
  });
  let detail = await app.fetchJson(`/boards/${created.board.id}`, {
    token: zoe.authToken,
  });
  assert.equal(detail.board.ownerPlayerId, noah.player.id);
  const events = app.env.DB.db
    .prepare(
      "select actor_player_id from board_events where event_type = 'owner_changed'",
    )
    .all();
  assert.equal(events.length, 1);
  assert.equal(events[0].actor_player_id, noah.player.id);

  // Next owner departs via account deletion → Zoe inherits.
  await app.fetchJson('/players/me', {
    method: 'DELETE',
    token: noah.authToken,
  });
  detail = await app.fetchJson(`/boards/${created.board.id}`, {
    token: zoe.authToken,
  });
  assert.equal(detail.board.ownerPlayerId, zoe.player.id);
});

test('player restore exchanges recovery secret for a fresh token', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  assert.ok(maya.recoverySecret, 'bootstrap returns a recovery secret');

  const restored = await app.fetchJson('/players/restore', {
    method: 'POST',
    body: { playerId: maya.player.id, recoverySecret: maya.recoverySecret },
  });
  assert.equal(restored.player.id, maya.player.id);
  assert.notEqual(restored.authToken, maya.authToken);

  // The fresh token authenticates.
  const me = await app.fetchJson('/players/me', { token: restored.authToken });
  assert.equal(me.player.id, maya.player.id);

  // A wrong secret is rejected.
  await app.fetchJson('/players/restore', {
    method: 'POST',
    body: { playerId: maya.player.id, recoverySecret: 'nope' },
    status: 401,
  });
});

test('rotating the recovery secret invalidates the old one', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');

  const rotated = await app.fetchJson('/players/recovery/rotate', {
    method: 'POST',
    token: maya.authToken,
  });
  assert.ok(rotated.recoverySecret);
  assert.notEqual(rotated.recoverySecret, maya.recoverySecret);

  // The old secret no longer restores.
  await app.fetchJson('/players/restore', {
    method: 'POST',
    body: { playerId: maya.player.id, recoverySecret: maya.recoverySecret },
    status: 401,
  });
  // The new secret does.
  const restored = await app.fetchJson('/players/restore', {
    method: 'POST',
    body: { playerId: maya.player.id, recoverySecret: rotated.recoverySecret },
  });
  assert.equal(restored.player.id, maya.player.id);
});

test('deleting a player removes participation and revokes the token', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });
  await app.submitResult(maya.authToken);

  const deleted = await app.fetchJson('/players/me', {
    method: 'DELETE',
    token: maya.authToken,
  });
  assert.equal(deleted.ok, true);

  // Token is revoked.
  await app.fetchJson('/players/me', { token: maya.authToken, status: 401 });
  // Recovery secret can no longer restore a deleted player.
  await app.fetchJson('/players/restore', {
    method: 'POST',
    body: { playerId: maya.player.id, recoverySecret: maya.recoverySecret },
    status: 401,
  });
  // Sole-member board was auto-deleted, and the result row is gone.
  const boards = app.env.DB.db
    .prepare('select deleted_at from boards where id = ?')
    .get(created.board.id);
  assert.ok(boards.deleted_at, 'board auto-deleted');
  const results = app.env.DB.db
    .prepare('select count(*) as n from challenge_results where player_id = ?')
    .get(maya.player.id);
  assert.equal(results.n, 0);
});

test('scheduled purge removes board events older than 14 days', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  // The board-create event is recent; insert one well outside the window.
  const old = new Date(Date.now() - 30 * 86_400_000).toISOString();
  app.env.DB.db
    .prepare(
      `insert into board_events (id, board_id, actor_player_id, event_type, created_at)
       values ('stale', (select id from boards limit 1), ?, 'join', ?)`,
    )
    .run(maya.player.id, old);

  const before = app.env.DB.db
    .prepare('select count(*) as n from board_events')
    .get().n;
  assert.ok(before >= 2);

  await app.runScheduled();

  const rows = app.env.DB.db.prepare('select created_at from board_events').all();
  assert.ok(rows.length >= 1, 'recent events retained');
  assert.ok(
    rows.every((r) => r.created_at !== old),
    'stale event purged',
  );
});

test('display names with reserved or blocked words are rejected', async () => {
  const app = await createApp();
  for (const name of ['admin', 'Cr0sscue', 'fuck', 'sh1t']) {
    const error = await app.fetchJson('/players/bootstrap', {
      method: 'POST',
      body: { displayName: name },
      status: 400,
    });
    assert.equal(error.error.code, 'invalid_display_name', name);
  }
  // A clean name still works.
  const ok = await app.bootstrap('Maya');
  assert.equal(ok.player.displayName, 'Maya');
});

test('rate limiter blocks requests over the limit', async () => {
  const app = await createApp();
  app.env.RL_IDENTITY = { async limit() {
    return { success: false };
  } };

  const error = await app.fetchJson('/players/bootstrap', {
    method: 'POST',
    body: { displayName: 'Maya' },
    status: 429,
  });
  assert.equal(error.error.code, 'rate_limited');
});

test('minimum-client gate rejects old, missing, and garbage versions (#256)', async () => {
  // Unset minimum (the default everywhere today) → no enforcement, even
  // without the header — all currently fielded clients keep working.
  const open = await createApp();
  await open.bootstrap('Maya');

  const gated = await createApp({ MIN_SUPPORTED_CLIENT: '1.4.3' });
  const expectTooOld = async (headers) => {
    const error = await gated.fetchJson('/players/bootstrap', {
      method: 'POST',
      body: { displayName: 'Maya' },
      status: 426,
      headers,
    });
    assert.equal(error.error.code, 'client_too_old');
  };
  await expectTooOld(undefined); // pre-header clients
  await expectTooOld({ 'x-crosscue-client': 'ios/1.4.2' }); // older patch
  await expectTooOld({ 'x-crosscue-client': 'ios/1.3.9' }); // older minor
  await expectTooOld({ 'x-crosscue-client': 'garbage' }); // unparsable

  // Equal and newer versions pass, on any route.
  const maya = await gated.fetchJson('/players/bootstrap', {
    method: 'POST',
    body: { displayName: 'Maya' },
    headers: { 'x-crosscue-client': 'ios/1.4.3' },
  });
  await gated.fetchJson('/boards', {
    token: maya.authToken,
    headers: { 'x-crosscue-client': 'android/2.0.0' },
  });

  // A malformed minimum must never take the API down — enforcement is
  // silently skipped rather than rejecting everyone.
  const misconfigured = await createApp({ MIN_SUPPORTED_CLIENT: 'oops' });
  await misconfigured.bootstrap('Maya');
});

function currentUtcDateOnly() {
  return new Date().toISOString().slice(0, 10);
}

function previousUtcWeekDateOnly() {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() - 7);
  return date.toISOString().slice(0, 10);
}

async function createApp(envOverrides = {}) {
  const db = new DatabaseSync(':memory:');
  const migrationsDir = new URL('../migrations/', import.meta.url);
  for (const file of readdirSync(migrationsDir).filter((f) => f.endsWith('.sql')).sort()) {
    db.exec(readFileSync(new URL(file, migrationsDir), 'utf8'));
  }

  const env = {
    DB: new D1DatabaseShim(db),
    PUBLIC_APP_URL: 'https://crosscue.pages.dev',
    APP_ENV: 'test',
    ...envOverrides,
  };

  return {
    env,
    async runScheduled() {
      await worker.scheduled({ cron: '7 3 * * *' }, env, { waitUntil() {} });
    },
    async bootstrap(displayName, options = {}) {
      const data = await this.fetchJson('/players/bootstrap', {
        method: 'POST',
        body: { displayName },
        headers: options.headers,
      });
      return data;
    },
    async submitResult(token, overrides = {}) {
      return this.fetchJson('/results', {
        method: 'POST',
        token,
        status: 202,
        body: {
          sourceId: 'crosshare_daily_mini',
          sourcePuzzleId: '2026-06-05',
          completedAt: new Date().toISOString(),
          elapsedMs: 90000,
          completionType: 'clean',
          cleanSolveEligible: true,
          puzzleTitle: 'Daily Mini',
          publishedOn: currentUtcDateOnly(),
          ...overrides,
        },
      });
    },
    async fetchJson(path, options = {}) {
      const headers = new Headers({ 'content-type': 'application/json' });
      if (options.token) headers.set('authorization', `Bearer ${options.token}`);
      for (const [name, value] of Object.entries(options.headers ?? {})) {
        headers.set(name, value);
      }
      const response = await worker.fetch(
        new Request(`${apiBase}${path}`, {
          method: options.method ?? 'GET',
          headers,
          body: options.body == null ? undefined : JSON.stringify(options.body),
        }),
        env,
      );
      const text = await response.text();
      const data = text ? JSON.parse(text) : null;
      assert.equal(
        response.status,
        options.status ?? 200,
        JSON.stringify(data, null, 2),
      );
      return data;
    },
    // Returns the raw Response for non-JSON routes (e.g. GET /avatars/...).
    async fetchRaw(path, options = {}) {
      const headers = new Headers();
      if (options.token) headers.set('authorization', `Bearer ${options.token}`);
      for (const [name, value] of Object.entries(options.headers ?? {})) {
        headers.set(name, value);
      }
      return worker.fetch(
        new Request(`${apiBase}${path}`, {
          method: options.method ?? 'GET',
          headers,
        }),
        env,
      );
    },
  };
}

// Minimal in-memory R2 bucket for the avatar tests. Implements only the
// surface src/avatars.ts uses: put/get/delete/list.
class R2BucketShim {
  constructor() {
    this.store = new Map(); // key -> Uint8Array
  }

  async put(key, value) {
    const bytes =
      value instanceof Uint8Array
        ? value
        : value instanceof ArrayBuffer
          ? new Uint8Array(value)
          : new TextEncoder().encode(String(value));
    this.store.set(key, bytes);
    return { key };
  }

  async get(key) {
    const bytes = this.store.get(key);
    if (!bytes) return null;
    return {
      body: bytes,
      httpEtag: `"${key}"`,
      writeHttpMetadata(headers) {
        headers.set('content-type', 'image/png');
      },
    };
  }

  async delete(keys) {
    for (const k of Array.isArray(keys) ? keys : [keys]) {
      this.store.delete(k);
    }
  }

  async list({ prefix } = {}) {
    const objects = [...this.store.keys()]
      .filter((k) => !prefix || k.startsWith(prefix))
      .map((key) => ({ key }));
    return { objects, truncated: false };
  }
}

// 1x1 PNGs with distinct bytes → distinct content hashes.
const PNG_A =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8' +
  'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
const PNG_B =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk' +
  '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

test('avatar photo stores in R2 and is served by reference (#268)', async () => {
  const app = await createApp({ AVATARS: new R2BucketShim() });
  const maya = await app.bootstrap('Maya');

  const updated = await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    body: { kind: 'photo', photoPngBase64: PNG_A },
  });

  const url = updated.player.avatar.photoUrl;
  assert.ok(
    !url.startsWith('data:'),
    `expected an https URL, got a data URL: ${url.slice(0, 24)}…`,
  );
  assert.match(url, /\/avatars\/[^/]+\/[a-f0-9]+\.png$/);

  // The public route serves the bytes with an immutable long cache.
  const path = new URL(url).pathname;
  const res = await app.fetchRaw(path);
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('content-type'), 'image/png');
  assert.match(res.headers.get('cache-control'), /immutable/);
  const served = new Uint8Array(await res.arrayBuffer());
  const expected = Uint8Array.from(atob(PNG_A), (c) => c.charCodeAt(0));
  assert.deepEqual(served, expected);
});

test('replacing a photo deletes the previous R2 object (#268)', async () => {
  const bucket = new R2BucketShim();
  const app = await createApp({ AVATARS: bucket });
  const maya = await app.bootstrap('Maya');

  const first = await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    body: { kind: 'photo', photoPngBase64: PNG_A },
  });
  const second = await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    body: { kind: 'photo', photoPngBase64: PNG_B },
  });

  // Exactly one object remains, and the old URL now 404s.
  assert.equal(bucket.store.size, 1);
  assert.notEqual(first.player.avatar.photoUrl, second.player.avatar.photoUrl);
  const oldPath = new URL(first.player.avatar.photoUrl).pathname;
  const gone = await app.fetchRaw(oldPath);
  assert.equal(gone.status, 404);
});

test('switching from photo to silhouette clears the R2 object (#268)', async () => {
  const bucket = new R2BucketShim();
  const app = await createApp({ AVATARS: bucket });
  const maya = await app.bootstrap('Maya');

  await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    body: { kind: 'photo', photoPngBase64: PNG_A },
  });
  const silhouette = await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    body: { kind: 'silhouette', silhouetteLook: 3 },
  });

  assert.equal(silhouette.player.avatar.kind, 'silhouette');
  assert.equal(silhouette.player.avatar.photoUrl, null);
  assert.equal(bucket.store.size, 0);
});

test('account deletion removes stored avatar objects (#268)', async () => {
  const bucket = new R2BucketShim();
  const app = await createApp({ AVATARS: bucket });
  const maya = await app.bootstrap('Maya');

  await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    body: { kind: 'photo', photoPngBase64: PNG_A },
  });
  assert.equal(bucket.store.size, 1);

  await app.fetchJson('/players/me', {
    method: 'DELETE',
    token: maya.authToken,
  });
  assert.equal(bucket.store.size, 0);
});

test('avatar route 404s for a missing object and serves even with a min-client gate (#268)', async () => {
  const app = await createApp({
    AVATARS: new R2BucketShim(),
    MIN_SUPPORTED_CLIENT: '99.0.0',
  });
  const maya = await app.bootstrap('Maya', {
    headers: { 'x-crosscue-client': 'ios/99.0.0' },
  });

  // Unknown key → 404.
  const missing = await app.fetchRaw('/avatars/nobody/deadbeef.png');
  assert.equal(missing.status, 404);

  // A real upload (sending the required client header past the gate)…
  const updated = await app.fetchJson('/players/me/avatar', {
    method: 'POST',
    token: maya.authToken,
    headers: { 'x-crosscue-client': 'ios/99.0.0' },
    body: { kind: 'photo', photoPngBase64: PNG_A },
  });
  // …is then readable WITHOUT a client header: image fetches are exempt.
  const path = new URL(updated.player.avatar.photoUrl).pathname;
  const res = await app.fetchRaw(path);
  assert.equal(res.status, 200);
});

class D1DatabaseShim {
  constructor(db) {
    this.db = db;
  }

  prepare(sql) {
    return new D1PreparedStatementShim(this.db, sql);
  }

  async batch(statements) {
    return statements.reduce(
      (promise, statement) => promise.then(async (results) => {
        results.push(await statement.run());
        return results;
      }),
      Promise.resolve([]),
    );
  }
}

class D1PreparedStatementShim {
  constructor(db, sql) {
    this.db = db;
    this.sql = sql;
    this.params = [];
  }

  bind(...params) {
    const bound = new D1PreparedStatementShim(this.db, this.sql);
    bound.params = params;
    return bound;
  }

  async run() {
    const statement = this.db.prepare(this.sql);
    statement.run(...this.params);
    return { success: true };
  }

  async all() {
    const statement = this.db.prepare(this.sql);
    return { results: statement.all(...this.params) };
  }

  async first() {
    const statement = this.db.prepare(this.sql);
    return statement.get(...this.params) ?? null;
  }
}
