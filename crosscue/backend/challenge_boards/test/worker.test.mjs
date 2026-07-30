import assert from 'node:assert/strict';
import test from 'node:test';

import {
  reassignOrphanedOwners,
  reconcileChunkSize,
  reconcileHeartbeatKey,
} from '../src/reconcile.ts';
import {
  purgeChunkSize,
  retentionHeartbeatKey,
} from '../src/retention.ts';
import {
  createApp,
  currentUtcDateOnly,
  R2BucketShim,
  withBatchFault,
  withD1Hooks,
} from './harness.mjs';

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

test('a mid-batch failure deleting a player rolls back — no partial state', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });
  await app.submitResult(maya.authToken);

  // Fault-inject the final `update players ... set deleted_at` statement so
  // it fails after the board departure, result deletion, and membership
  // anonymization statements in the same request-level batch.
  const realDb = app.env.DB;
  app.env.DB = withBatchFault(
    realDb,
    /update players\s+set deleted_at/i,
    new Error('simulated d1 failure'),
  );

  await app.fetchJson('/players/me', {
    method: 'DELETE',
    token: maya.authToken,
    status: 500,
  });

  // No partial state: the whole batch — including the board departure and
  // account cleanup statements ahead of the fault — rolls back together.
  const board = realDb.db
    .prepare('select deleted_at from boards where id = ?')
    .get(created.board.id);
  assert.equal(board.deleted_at, null, 'sole-member board must remain active');

  const results = realDb.db
    .prepare('select count(*) as n from challenge_results where player_id = ?')
    .get(maya.player.id);
  assert.equal(results.n, 1, 'solve result must survive the rolled-back batch');

  const membership = realDb.db
    .prepare('select display_name from memberships where player_id = ?')
    .get(maya.player.id);
  assert.notEqual(membership.display_name, 'Deleted');

  const player = realDb.db
    .prepare('select deleted_at, display_name from players where id = ?')
    .get(maya.player.id);
  assert.equal(player.deleted_at, null);
  assert.equal(player.display_name, 'Maya');
});

test('a delete failure on one of multiple boards rolls back every board departure and account cleanup', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const solo = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Solo Board' },
    status: 201,
  });
  const shared = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Shared Board' },
    status: 201,
  });
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: shared.inviteLink },
  });
  await app.submitResult(maya.authToken);

  // Fault the shared board's owner-change event. The solo-board deletion,
  // both membership closes, all departure events, and account cleanup share
  // this batch and must roll back regardless of statement ordering.
  const realDb = app.env.DB;
  app.env.DB = withBatchFault(
    realDb,
    (statement) =>
      /owner_changed/i.test(statement.sql) &&
      statement.params[2] === shared.board.id,
    new Error('simulated second-board d1 failure'),
  );

  await app.fetchJson('/players/me', {
    method: 'DELETE',
    token: maya.authToken,
    status: 500,
  });

  const boards = realDb.db
    .prepare(
      'select id, deleted_at, owner_player_id from boards where id in (?, ?)',
    )
    .all(solo.board.id, shared.board.id);
  assert.equal(boards.length, 2);
  assert.ok(boards.every((board) => board.deleted_at === null));
  assert.equal(
    boards.find((board) => board.id === shared.board.id).owner_player_id,
    maya.player.id,
  );

  const memberships = realDb.db
    .prepare(
      `select board_id, left_at, membership_state, display_name
       from memberships where player_id = ?`,
    )
    .all(maya.player.id);
  assert.equal(memberships.length, 2);
  assert.ok(memberships.every((membership) => membership.left_at === null));
  assert.ok(
    memberships.every(
      (membership) =>
        membership.membership_state === 'active' &&
        membership.display_name === 'Maya',
    ),
  );

  const departureEvents = realDb.db
    .prepare(
      `select count(*) as n from board_events
       where actor_player_id = ?
         and event_type in ('leave', 'owner_changed')`,
    )
    .get(maya.player.id);
  assert.equal(departureEvents.n, 0);

  const results = realDb.db
    .prepare('select count(*) as n from challenge_results where player_id = ?')
    .get(maya.player.id);
  assert.equal(results.n, 1);

  const player = realDb.db
    .prepare('select deleted_at, display_name from players where id = ?')
    .get(maya.player.id);
  assert.equal(player.deleted_at, null);
  assert.equal(player.display_name, 'Maya');
});

test('a mid-batch failure creating a board rolls back — no orphan board', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');

  // Fault-inject the memberships insert so it fails after the boards insert
  // in the same batch would otherwise have committed.
  const realDb = app.env.DB;
  app.env.DB = withBatchFault(
    realDb,
    /insert into memberships/i,
    new Error('simulated d1 failure'),
  );

  await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 500,
  });

  // No partial state: an orphan board with zero members would be the bug.
  const board = realDb.db
    .prepare('select id from boards where name = ?')
    .get('Friday Crew');
  assert.equal(board, undefined, 'board row must not exist');

  const membership = realDb.db
    .prepare('select board_id from memberships where player_id = ?')
    .get(maya.player.id);
  assert.equal(membership, undefined, 'membership row must not exist');
});

test('a mid-batch failure updating a player rolls back — no display-name drift', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  // Fault-inject the memberships update, not the players update. Note the
  // \s+ (not .*) — the memberships statement is a multi-line template
  // literal, and `.` does not match newlines.
  const realDb = app.env.DB;
  app.env.DB = withBatchFault(
    realDb,
    /update memberships\s+set display_name/i,
    new Error('simulated d1 failure'),
  );

  await app.fetchJson('/players/me', {
    method: 'PATCH',
    token: maya.authToken,
    body: { displayName: 'Mayaaaa' },
    status: 500,
  });

  // No partial state: drift between players.display_name and the
  // denormalized memberships.display_name copy would be the bug.
  const player = realDb.db
    .prepare('select display_name from players where id = ?')
    .get(maya.player.id);
  assert.equal(player.display_name, 'Maya');

  const membership = realDb.db
    .prepare('select display_name from memberships where player_id = ?')
    .get(maya.player.id);
  assert.equal(membership.display_name, 'Maya');
});

test('a mid-batch failure leaving a board rolls back — no partial state', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  // Board creation also writes a board_events row via its own batch, so the
  // fault must be installed only after all setup is complete — otherwise
  // the /boards call above would fail too.
  const realDb = app.env.DB;
  app.env.DB = withBatchFault(
    realDb,
    /insert into board_events/i,
    new Error('simulated d1 failure'),
  );

  await app.fetchJson(`/boards/${created.board.id}/leave`, {
    method: 'POST',
    token: maya.authToken,
    status: 500,
  });

  // No partial state: the membership close must not have survived without
  // its paired audit event.
  const membership = realDb.db
    .prepare(
      'select left_at, membership_state from memberships where board_id = ? and player_id = ?',
    )
    .get(created.board.id, maya.player.id);
  assert.equal(membership.left_at, null, 'membership must still be active');
  assert.notEqual(membership.membership_state, 'left');

  const events = realDb.db
    .prepare(
      "select count(*) as n from board_events where board_id = ? and event_type = 'leave'",
    )
    .get(created.board.id);
  assert.equal(events.n, 0, 'no leave event should exist');
});

test('a mid-batch failure joining a board rolls back — no partial membership', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  // Board creation also writes a board_events row via its own batch, so the
  // fault must be installed only after all setup is complete — otherwise
  // the /boards call above would fail too.
  const realDb = app.env.DB;
  app.env.DB = withBatchFault(
    realDb,
    /insert into board_events/i,
    new Error('simulated d1 failure'),
  );

  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: created.inviteLink },
    status: 500,
  });

  // No partial state: the memberships upsert must not have survived without
  // its paired audit event.
  const membership = realDb.db
    .prepare(
      'select left_at, membership_state from memberships where board_id = ? and player_id = ?',
    )
    .get(created.board.id, noah.player.id);
  assert.equal(membership, undefined, 'no membership row should exist');

  const events = realDb.db
    .prepare(
      "select count(*) as n from board_events where board_id = ? and event_type = 'join'",
    )
    .get(created.board.id);
  assert.equal(events.n, 0, 'no join event should exist');
});

test('a mid-batch failure removing a member rolls back — no partial state', async () => {
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

  // Fault-inject the board_events insert so it fails after the memberships
  // update in the same batch would otherwise have committed.
  const realDb = app.env.DB;
  app.env.DB = withBatchFault(
    realDb,
    /insert into board_events/i,
    new Error('simulated d1 failure'),
  );

  await app.fetchJson(
    `/boards/${created.board.id}/members/${noah.player.id}`,
    { method: 'DELETE', token: maya.authToken, status: 500 },
  );

  // No partial state: the membership close must not have survived without
  // its paired audit event.
  const membership = realDb.db
    .prepare(
      'select left_at, membership_state from memberships where board_id = ? and player_id = ?',
    )
    .get(created.board.id, noah.player.id);
  assert.equal(membership.left_at, null, 'membership must still be active');
  assert.notEqual(membership.membership_state, 'removed');

  const events = realDb.db
    .prepare(
      "select count(*) as n from board_events where board_id = ? and event_type = 'member_removed'",
    )
    .get(created.board.id);
  assert.equal(events.n, 0, 'no member_removed event should exist');
});

test('a mid-batch failure regenerating an invite rolls back — no partial state', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew' },
    status: 201,
  });

  const before = app.env.DB.db
    .prepare(
      'select invite_code_hash, invite_version from boards where id = ?',
    )
    .get(created.board.id);

  // Fault-inject the board_events insert so it fails after the boards
  // invite-fields update (including invite_version = invite_version + 1) in
  // the same batch would otherwise have committed.
  const realDb = app.env.DB;
  app.env.DB = withBatchFault(
    realDb,
    /insert into board_events/i,
    new Error('simulated d1 failure'),
  );

  await app.fetchJson(`/boards/${created.board.id}/invite/regenerate`, {
    method: 'POST',
    token: maya.authToken,
    status: 500,
  });

  // No partial state: a silently incremented invite_version (or rotated
  // hash) without the paired audit event would be the bug.
  const after = realDb.db
    .prepare(
      'select invite_code_hash, invite_version from boards where id = ?',
    )
    .get(created.board.id);
  assert.equal(after.invite_code_hash, before.invite_code_hash);
  assert.equal(after.invite_version, before.invite_version);

  const events = realDb.db
    .prepare(
      "select count(*) as n from board_events where board_id = ? and event_type = 'invite_regenerate'",
    )
    .get(created.board.id);
  assert.equal(events.n, 0, 'no invite_regenerate event should exist');
});

test('a mid-batch failure transferring ownership rolls back the entire board departure', async () => {
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

  // Both event inserts are in one batch. Match the owner-change statement by
  // its literal event type so the failure happens after the membership close,
  // leave event, and owner update would otherwise have executed.
  const realDb = app.env.DB;
  app.env.DB = withBatchFault(
    realDb,
    /select \?, id, owner_player_id, 'owner_changed'/i,
    new Error('simulated d1 failure'),
  );

  await app.fetchJson(`/boards/${created.board.id}/leave`, {
    method: 'POST',
    token: maya.authToken,
    status: 500,
  });

  // The entire departure rolls back: Maya remains both owner and an active
  // member, and neither departure event survives.
  const board = realDb.db
    .prepare('select owner_player_id from boards where id = ?')
    .get(created.board.id);
  assert.equal(board.owner_player_id, maya.player.id);

  const events = realDb.db
    .prepare(
      "select count(*) as n from board_events where board_id = ? and event_type in ('leave', 'owner_changed')",
    )
    .get(created.board.id);
  assert.equal(events.n, 0, 'no departure event should exist');

  const membership = realDb.db
    .prepare(
      'select left_at, membership_state from memberships where board_id = ? and player_id = ?',
    )
    .get(created.board.id, maya.player.id);
  assert.equal(membership.left_at, null, 'membership must remain active');
  assert.equal(membership.membership_state, 'active');
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

test('scheduled purge deletes stale events across chunks without exceeding D1 bind limits', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Retention batch' },
    status: 201,
  });
  const old = new Date(Date.now() - 30 * 86_400_000).toISOString();
  const total = purgeChunkSize + 1;
  for (let index = 0; index < total; index += 1) {
    app.env.DB.db
      .prepare(
        `insert into board_events (id, board_id, actor_player_id, event_type, created_at)
         values (?, ?, ?, 'join', ?)`,
      )
      .run(`old-event-${index}`, created.board.id, maya.player.id, old);
  }

  const realDb = app.env.DB;
  app.env.DB = withD1Hooks(realDb, {
    beforeRun({ params }) {
      assert.ok(
        params.length <= 100,
        `D1 statement bound ${params.length} values; its per-statement limit is 100`,
      );
    },
  });
  await app.runScheduled();

  assert.equal(
    realDb.db.prepare('select count(*) as n from board_events where created_at = ?').get(old).n,
    0,
  );
});

test('retention heartbeat: scheduled run records it; /health/retention exposes it (#262)', async () => {
  const app = await createApp();

  // Before any run, the endpoint is reachable (public, ungated) and null.
  const before = await app.fetchJson('/health/retention');
  assert.equal(before.lastPurgeAt, null);
  assert.equal(before.lastReconcileAt, null);

  await app.runScheduled();

  const after = await app.fetchJson('/health/retention');
  assert.ok(after.lastPurgeAt, 'heartbeat recorded');
  assert.ok(after.lastReconcileAt, 'reconciliation heartbeat recorded');
  assert.ok(
    !Number.isNaN(Date.parse(after.lastPurgeAt)),
    'heartbeat is an ISO datetime',
  );
  assert.ok(
    !Number.isNaN(Date.parse(after.lastReconcileAt)),
    'reconciliation heartbeat is an ISO datetime',
  );
});

test('retention heartbeat endpoint is exempt from the min-client gate (#262)', async () => {
  // A monitoring curl carries no X-Crosscue-Client header; the health check
  // must not 426 when the force-upgrade lever is armed.
  const app = await createApp({ MIN_SUPPORTED_CLIENT: '99.0.0' });
  const res = await app.fetchRaw('/health/retention');
  assert.equal(res.status, 200);
});

test('scheduled maintenance still reconciles and records its heartbeat when the purge fails', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const board = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Independent maintenance jobs' },
    status: 201,
  });
  const realDb = app.env.DB;
  realDb.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), board.board.id, maya.player.id);

  let purgeFailed = false;
  app.env.DB = withD1Hooks(realDb, {
    beforeRun({ sql }) {
      if (!purgeFailed && /delete from board_events/i.test(sql)) {
        purgeFailed = true;
        throw new Error('purge failed');
      }
    },
  });

  await assert.rejects(app.runScheduled(), /purge failed/);
  assert.equal(purgeFailed, true);
  assert.ok(
    realDb.db.prepare('select deleted_at from boards where id = ?').get(board.board.id).deleted_at,
    'reconciliation must still close the empty board',
  );
  assert.equal(
    realDb.db.prepare('select value from ops_meta where key = ?').get(retentionHeartbeatKey),
    undefined,
    'a failed purge must not advance the purge heartbeat',
  );
  assert.ok(
    realDb.db.prepare('select value from ops_meta where key = ?').get(reconcileHeartbeatKey).value,
    'the successful reconciliation must advance its own heartbeat',
  );
});

test('scheduled maintenance completes both jobs and aggregates failures when both heartbeat writes fail', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const board = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Failed maintenance heartbeats' },
    status: 201,
  });
  const realDb = app.env.DB;
  const old = new Date(Date.now() - 30 * 86_400_000).toISOString();
  realDb.db
    .prepare(
      `insert into board_events (id, board_id, actor_player_id, event_type, created_at)
       values ('stale-before-heartbeat-failure', ?, ?, 'join', ?)`,
    )
    .run(board.board.id, maya.player.id, old);
  realDb.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), board.board.id, maya.player.id);

  app.env.DB = withD1Hooks(realDb, {
    beforeRun({ params }) {
      if (params.includes(retentionHeartbeatKey)) {
        throw new Error('retention heartbeat failed');
      }
      if (params.includes(reconcileHeartbeatKey)) {
        throw new Error('reconcile heartbeat failed');
      }
    },
  });

  await assert.rejects(app.runScheduled(), (error) => {
    assert.ok(error instanceof AggregateError);
    assert.deepEqual(
      error.errors.map((failure) => failure.message),
      ['retention heartbeat failed', 'reconcile heartbeat failed'],
    );
    return true;
  });
  assert.equal(
    realDb.db
      .prepare('select count(*) as n from board_events where id = ?')
      .get('stale-before-heartbeat-failure').n,
    0,
    'the purge must commit before its heartbeat failure',
  );
  assert.ok(
    realDb.db.prepare('select deleted_at from boards where id = ?').get(board.board.id).deleted_at,
    'reconciliation must commit before its heartbeat failure',
  );
  assert.equal(
    realDb.db
      .prepare('select count(*) as n from ops_meta where key in (?, ?)')
      .get(retentionHeartbeatKey, reconcileHeartbeatKey).n,
    0,
    'failed heartbeat writes must not report either job as healthy',
  );
});

// The routes can no longer produce a board with zero active members and a
// null deleted_at, or an owner_player_id that isn't an active member —
// boardDepartureStatements guards both writes in SQL, evaluated inside the
// batch. These states only exist on rows written before that guarding landed.
// Simulate them by writing directly to the db, bypassing the routes, the same
// way the fault-injection tests bypass them to force partial-batch states.
test('scheduled reconcile closes a board with zero active members', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Solo Board' },
    status: 201,
  });

  // Simulate a pre-fix row: the membership closed but the board never got
  // marked deleted (the guarded departure SQL does both in one batch).
  app.env.DB.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), created.board.id, maya.player.id);

  const before = app.env.DB.db
    .prepare('select deleted_at from boards where id = ?')
    .get(created.board.id);
  assert.equal(before.deleted_at, null, 'board must start stuck open');

  await app.runScheduled();

  const after = app.env.DB.db
    .prepare('select deleted_at from boards where id = ?')
    .get(created.board.id);
  assert.ok(after.deleted_at, 'empty board must be closed by the sweep');
});

test('scheduled reconcile reassigns an orphaned owner to the earliest-joined active member and writes an owner_changed event', async () => {
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

  // Simulate a pre-fix row: Maya (the owner) leaves without the ownership
  // transfer the guarded departure SQL does in the same batch. Noah stays
  // active, so the board is not empty — only ownership is orphaned.
  app.env.DB.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), created.board.id, maya.player.id);

  const before = app.env.DB.db
    .prepare('select owner_player_id, deleted_at from boards where id = ?')
    .get(created.board.id);
  assert.equal(before.owner_player_id, maya.player.id, 'owner must start stale');
  assert.equal(before.deleted_at, null);

  await app.runScheduled();

  const after = app.env.DB.db
    .prepare('select owner_player_id from boards where id = ?')
    .get(created.board.id);
  assert.equal(after.owner_player_id, noah.player.id);

  const ownerChangedEvents = app.env.DB.db
    .prepare(
      "select actor_player_id from board_events where board_id = ? and event_type = 'owner_changed'",
    )
    .all(created.board.id);
  assert.equal(ownerChangedEvents.length, 1);
  assert.equal(ownerChangedEvents[0].actor_player_id, noah.player.id);
});

test('scheduled reconcile repairs a null owner with a deterministic player-id tie-break', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const bree = await app.bootstrap('Bree');
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Deterministic owner repair' },
    status: 201,
  });
  for (const player of [noah, bree]) {
    await app.fetchJson('/invites/join', {
      method: 'POST',
      token: player.authToken,
      body: { inviteLink: created.inviteLink },
    });
  }

  const joinedAt = new Date().toISOString();
  app.env.DB.db
    .prepare('update memberships set joined_at = ? where board_id = ?')
    .run(joinedAt, created.board.id);
  app.env.DB.db
    .prepare('update boards set owner_player_id = null where id = ?')
    .run(created.board.id);

  await app.runScheduled();

  const expectedOwnerId = [maya.player.id, noah.player.id, bree.player.id].sort()[0];
  assert.equal(
    app.env.DB.db
      .prepare('select owner_player_id from boards where id = ?')
      .get(created.board.id).owner_player_id,
    expectedOwnerId,
  );
  assert.equal(
    app.env.DB.db
      .prepare(
        "select actor_player_id from board_events where board_id = ? and event_type = 'owner_changed'",
      )
      .get(created.board.id).actor_player_id,
    expectedOwnerId,
  );
});

test('scheduled reconcile leaves a healthy database untouched — no boards deleted, no owners changed, no spurious events', async () => {
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

  const snapshot = () => ({
    board: app.env.DB.db
      .prepare('select owner_player_id, deleted_at from boards where id = ?')
      .get(created.board.id),
    eventCount: app.env.DB.db
      .prepare('select count(*) as n from board_events')
      .get().n,
    ownerChangedCount: app.env.DB.db
      .prepare("select count(*) as n from board_events where event_type = 'owner_changed'")
      .get().n,
  });

  const before = snapshot();
  assert.equal(before.board.owner_player_id, maya.player.id);
  assert.equal(before.board.deleted_at, null);
  assert.equal(before.ownerChangedCount, 0);

  await app.runScheduled();
  await app.runScheduled();

  assert.deepEqual(snapshot(), before, 'a healthy board must be untouched by the sweep');
});

test('scheduled reconcile is idempotent — repairs on the first pass, does nothing on the second', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const bree = await app.bootstrap('Bree');

  // Board 1: will be stuck empty (zero active members, deleted_at null).
  const emptyBoard = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Solo Board' },
    status: 201,
  });
  app.env.DB.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), emptyBoard.board.id, maya.player.id);

  // Board 2: will have an orphaned owner (Noah owns, Bree is the sole
  // remaining active member and should inherit).
  const ownerBoard = await app.fetchJson('/boards', {
    method: 'POST',
    token: noah.authToken,
    body: { name: 'Trivia Night' },
    status: 201,
  });
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: bree.authToken,
    body: { inviteLink: ownerBoard.inviteLink },
  });
  app.env.DB.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), ownerBoard.board.id, noah.player.id);

  const snapshot = () => ({
    emptyDeletedAt: app.env.DB.db
      .prepare('select deleted_at from boards where id = ?')
      .get(emptyBoard.board.id).deleted_at,
    owner: app.env.DB.db
      .prepare('select owner_player_id from boards where id = ?')
      .get(ownerBoard.board.id).owner_player_id,
    ownerChangedCount: app.env.DB.db
      .prepare(
        "select count(*) as n from board_events where board_id = ? and event_type = 'owner_changed'",
      )
      .get(ownerBoard.board.id).n,
  });

  // First pass: both problems get repaired.
  await app.runScheduled();
  const afterFirst = snapshot();
  assert.ok(afterFirst.emptyDeletedAt, 'empty board closed on first pass');
  assert.equal(afterFirst.owner, bree.player.id, 'ownership reassigned on first pass');
  assert.equal(afterFirst.ownerChangedCount, 1);

  // Second pass on the same data: nothing left to repair, so nothing changes.
  await app.runScheduled();
  const afterSecond = snapshot();
  assert.deepEqual(afterSecond, afterFirst, 'second pass must be a no-op');
});

test('scheduled reconcile rechecks empty-board state at the repair write and reports only actual closes', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const board = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Race-safe empty board' },
    status: 201,
  });
  const realDb = app.env.DB;
  realDb.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), board.board.id, maya.player.id);

  let joinedImmediatelyBeforeRepair = false;
  app.env.DB = withD1Hooks(realDb, {
    beforeBatch({ statements }) {
      if (
        !joinedImmediatelyBeforeRepair &&
        statements.some(
          (statement) =>
            /update boards/i.test(statement.sql) &&
            /deleted_at/i.test(statement.sql),
        )
      ) {
        joinedImmediatelyBeforeRepair = true;
        realDb.db
          .prepare(
            "update memberships set left_at = null, membership_state = 'active' where board_id = ? and player_id = ?",
          )
          .run(board.board.id, maya.player.id);
      }
    },
    beforeRun({ sql }) {
      if (!joinedImmediatelyBeforeRepair && /update boards/i.test(sql) && /deleted_at/i.test(sql)) {
        joinedImmediatelyBeforeRepair = true;
        realDb.db
          .prepare(
            "update memberships set left_at = null, membership_state = 'active' where board_id = ? and player_id = ?",
          )
          .run(board.board.id, maya.player.id);
      }
    },
  });

  const logs = await scheduledLogs(app);
  assert.equal(joinedImmediatelyBeforeRepair, true, 'test hook must race the repair write');
  assert.equal(
    realDb.db.prepare('select deleted_at from boards where id = ?').get(board.board.id).deleted_at,
    null,
    'a board that regained a member must not be closed from a stale candidate',
  );
  assert.equal(
    reconcileLog(logs).boardsClosed,
    0,
    'the reconcile counter must reflect the conditional update result',
  );
});

test('scheduled reconcile rechecks ownership at the repair write and emits no false owner_changed event', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const board = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Race-safe owner repair' },
    status: 201,
  });
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: board.inviteLink },
  });
  const realDb = app.env.DB;
  realDb.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), board.board.id, maya.player.id);

  let ownershipRestoredImmediatelyBeforeRepair = false;
  const restoreOwner = () => {
    if (ownershipRestoredImmediatelyBeforeRepair) return;
    ownershipRestoredImmediatelyBeforeRepair = true;
    realDb.db
      .prepare(
        "update memberships set left_at = null, membership_state = 'active' where board_id = ? and player_id = ?",
      )
      .run(board.board.id, maya.player.id);
  };
  app.env.DB = withD1Hooks(realDb, {
    beforeBatch({ statements }) {
      if (statements.some((statement) => /update boards/i.test(statement.sql) && /owner_player_id/i.test(statement.sql))) {
        restoreOwner();
      }
    },
    beforeRun({ sql }) {
      if (/update boards/i.test(sql) && /owner_player_id/i.test(sql)) restoreOwner();
    },
  });

  const logs = await scheduledLogs(app);
  assert.equal(ownershipRestoredImmediatelyBeforeRepair, true, 'test hook must race the ownership write');
  assert.equal(
    realDb.db.prepare('select owner_player_id from boards where id = ?').get(board.board.id).owner_player_id,
    maya.player.id,
    'a valid owner must not be overwritten from a stale candidate',
  );
  assert.equal(
    realDb.db
      .prepare("select count(*) as n from board_events where board_id = ? and event_type = 'owner_changed'")
      .get(board.board.id).n,
    0,
    'a skipped ownership update must not produce an audit event',
  );
  assert.equal(reconcileLog(logs).ownersReassigned, 0);
});

test('scheduled reconcile does not assign a successor who leaves immediately before the repair transaction', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const board = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Race-safe successor repair' },
    status: 201,
  });
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: board.inviteLink },
  });
  const realDb = app.env.DB;
  realDb.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), board.board.id, maya.player.id);

  let successorLeftImmediatelyBeforeRepair = false;
  const leaveSuccessor = () => {
    if (successorLeftImmediatelyBeforeRepair) return;
    successorLeftImmediatelyBeforeRepair = true;
    realDb.db
      .prepare(
        "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
      )
      .run(new Date().toISOString(), board.board.id, noah.player.id);
  };
  app.env.DB = withD1Hooks(realDb, {
    beforeBatch({ statements }) {
      if (statements.some((statement) => /update boards/i.test(statement.sql) && /owner_player_id/i.test(statement.sql))) {
        leaveSuccessor();
      }
    },
    beforeRun({ sql }) {
      if (/update boards/i.test(sql) && /owner_player_id/i.test(sql)) leaveSuccessor();
    },
  });

  const logs = await scheduledLogs(app);
  assert.equal(successorLeftImmediatelyBeforeRepair, true, 'test hook must race the ownership write');
  assert.equal(
    realDb.db.prepare('select owner_player_id from boards where id = ?').get(board.board.id).owner_player_id,
    maya.player.id,
    'a departed candidate successor must not become the board owner',
  );
  assert.equal(
    realDb.db
      .prepare("select count(*) as n from board_events where board_id = ? and event_type = 'owner_changed'")
      .get(board.board.id).n,
    0,
  );
  assert.equal(reconcileLog(logs).ownersReassigned, 0);
});

test('scheduled reconcile rolls back an owner change when its owner_changed event fails', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const board = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Atomic owner repair' },
    status: 201,
  });
  await app.fetchJson('/invites/join', {
    method: 'POST',
    token: noah.authToken,
    body: { inviteLink: board.inviteLink },
  });
  const realDb = app.env.DB;
  realDb.db
    .prepare(
      "update memberships set left_at = ?, membership_state = 'left' where board_id = ? and player_id = ?",
    )
    .run(new Date().toISOString(), board.board.id, maya.player.id);
  app.env.DB = withBatchFault(
    realDb,
    (statement) =>
      /insert into board_events/i.test(statement.sql) &&
      (/owner_changed/i.test(statement.sql) || statement.params.includes('owner_changed')),
    new Error('owner_changed write failed'),
  );

  await assert.rejects(app.runScheduled(), /owner_changed write failed/);
  assert.equal(
    realDb.db.prepare('select owner_player_id from boards where id = ?').get(board.board.id).owner_player_id,
    maya.player.id,
    'the ownership write must roll back with its audit event',
  );
  assert.equal(
    realDb.db
      .prepare("select count(*) as n from board_events where board_id = ? and event_type = 'owner_changed'")
      .get(board.board.id).n,
    0,
  );
  assert.ok(
    realDb.db.prepare('select value from ops_meta where key = ?').get(retentionHeartbeatKey).value,
    'the successful purge must retain its own heartbeat',
  );
  assert.equal(
    realDb.db.prepare('select value from ops_meta where key = ?').get(reconcileHeartbeatKey),
    undefined,
    'a failed reconciliation must not advance its heartbeat',
  );
});

test('orphan-owner reconciliation stops after a full unrepairable chunk instead of rescanning it forever', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const now = new Date().toISOString();
  for (let index = 0; index < reconcileChunkSize; index += 1) {
    insertLegacyBoard(app.env.DB.db, {
      id: `unrepairable-${index}`,
      ownerPlayerId: null,
      createdByPlayerId: maya.player.id,
      now,
    });
  }

  const realDb = app.env.DB;
  let batches = 0;
  app.env.DB = withD1Hooks(realDb, {
    beforeBatch() {
      batches += 1;
      if (batches > 1) {
        throw new Error('reconciliation retried an unrepairable full chunk');
      }
    },
  });

  assert.equal(await reassignOrphanedOwners(app.env), 0);
  assert.ok(batches <= 1, 'an unrepairable full chunk must not be retried');
});

test('scheduled reconciliation stays within the free-plan D1 statement budget for a full repair chunk', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const now = new Date().toISOString();
  for (let index = 0; index < reconcileChunkSize; index += 1) {
    const id = `budget-owner-${index}`;
    insertLegacyBoard(app.env.DB.db, {
      id,
      ownerPlayerId: maya.player.id,
      createdByPlayerId: maya.player.id,
      now,
    });
    app.env.DB.db
      .prepare(
        `insert into memberships (board_id, player_id, display_name, joined_at, left_at, membership_state)
         values (?, ?, ?, ?, null, 'active')`,
      )
      .run(id, noah.player.id, noah.player.displayName, now);
  }

  const realDb = app.env.DB;
  let statements = 0;
  app.env.DB = withD1Hooks(realDb, {
    beforeAll() {
      statements += 1;
    },
    beforeFirst() {
      statements += 1;
    },
    beforeRun() {
      statements += 1;
    },
  });
  await app.runScheduled();

  assert.ok(
    statements <= 50,
    `scheduled reconciliation used ${statements} D1 statements; it must fit the 50-statement free-plan limit`,
  );
  assert.equal(
    realDb.db.prepare('select count(*) as n from boards where owner_player_id = ?').get(noah.player.id).n,
    reconcileChunkSize,
  );
});

test('scheduled reconciliation finishes every owner repair beyond one chunk and logs the actual total', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const noah = await app.bootstrap('Noah');
  const now = new Date().toISOString();
  const total = reconcileChunkSize + 1;
  for (let index = 0; index < total; index += 1) {
    const id = `beyond-chunk-owner-${index}`;
    insertLegacyBoard(app.env.DB.db, {
      id,
      ownerPlayerId: maya.player.id,
      createdByPlayerId: maya.player.id,
      now,
    });
    app.env.DB.db
      .prepare(
        `insert into memberships (board_id, player_id, display_name, joined_at, left_at, membership_state)
         values (?, ?, ?, ?, null, 'active')`,
      )
      .run(id, noah.player.id, noah.player.displayName, now);
  }

  const logs = await scheduledLogs(app);
  assert.equal(
    app.env.DB.db.prepare('select count(*) as n from boards where owner_player_id = ?').get(noah.player.id).n,
    total,
  );
  assert.equal(
    app.env.DB.db
      .prepare("select count(*) as n from board_events where event_type = 'owner_changed'")
      .get().n,
    total,
  );
  assert.equal(reconcileLog(logs).ownersReassigned, total);
});

test('scheduled reconciliation closes every empty board beyond one chunk and logs the actual total', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  const now = new Date().toISOString();
  const total = reconcileChunkSize + 1;
  for (let index = 0; index < total; index += 1) {
    insertLegacyBoard(app.env.DB.db, {
      id: `beyond-chunk-empty-${index}`,
      ownerPlayerId: maya.player.id,
      createdByPlayerId: maya.player.id,
      now,
    });
  }

  const logs = await scheduledLogs(app);
  assert.equal(
    app.env.DB.db
      .prepare("select count(*) as n from boards where id like 'beyond-chunk-empty-%' and deleted_at is not null")
      .get().n,
    total,
  );
  assert.equal(reconcileLog(logs).boardsClosed, total);
});

function insertLegacyBoard(db, { id, ownerPlayerId, createdByPlayerId, now }) {
  db.prepare(
    `insert into boards (
      id, name, source_id, ranking_mode, invite_code_hash, invite_version,
      invite_expires_at, invite_rotated_at, created_by_player_id, created_at,
      owner_player_id
    ) values (?, ?, 'crosshare_daily_mini', 'average_time', ?, 1, ?, ?, ?, ?, ?)`,
  ).run(
    id,
    id,
    `invite-${id}`,
    now,
    now,
    createdByPlayerId,
    now,
    ownerPlayerId,
  );
}

async function scheduledLogs(app) {
  const originalLog = console.log;
  const logs = [];
  console.log = (line) => logs.push(line);
  try {
    await app.runScheduled();
  } finally {
    console.log = originalLog;
  }
  return logs;
}

function reconcileLog(logs) {
  const line = logs
    .map((line) => JSON.parse(line))
    .find((entry) => entry.job === 'reconcile_boards');
  assert.ok(line, 'scheduled reconciliation must emit its own structured log line');
  return line;
}

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

function previousUtcWeekDateOnly() {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() - 7);
  return date.toISOString().slice(0, 10);
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
