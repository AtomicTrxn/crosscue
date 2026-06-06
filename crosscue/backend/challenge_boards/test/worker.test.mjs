import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
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
  db.exec(readFileSync(new URL('../migrations/0001_core_membership.sql', import.meta.url), 'utf8'));
  db.exec(readFileSync(new URL('../migrations/0002_challenge_results.sql', import.meta.url), 'utf8'));

  const env = {
    DB: new D1DatabaseShim(db),
    PUBLIC_APP_URL: 'https://crosscue.app',
    APP_ENV: 'test',
  };

  return {
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
