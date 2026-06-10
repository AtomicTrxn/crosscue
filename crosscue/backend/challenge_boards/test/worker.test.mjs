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
    elapsedMs: 1000,
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

function currentUtcDateOnly() {
  return new Date().toISOString().slice(0, 10);
}

function previousUtcWeekDateOnly() {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() - 7);
  return date.toISOString().slice(0, 10);
}

async function createApp() {
  const db = new DatabaseSync(':memory:');
  const migrationsDir = new URL('../migrations/', import.meta.url);
  for (const file of readdirSync(migrationsDir).filter((f) => f.endsWith('.sql')).sort()) {
    db.exec(readFileSync(new URL(file, migrationsDir), 'utf8'));
  }

  const env = {
    DB: new D1DatabaseShim(db),
    PUBLIC_APP_URL: 'https://crosscue.app',
    APP_ENV: 'test',
  };

  return {
    env,
    async runScheduled() {
      await worker.scheduled({ cron: '7 3 * * *' }, env, { waitUntil() {} });
    },
    async bootstrap(displayName) {
      const data = await this.fetchJson('/players/bootstrap', {
        method: 'POST',
        body: { displayName },
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
  };
}

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
