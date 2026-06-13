// Worker consumer of the shared API contract fixtures (#260).
//
// Drives the REAL router through a deterministic flow + reject/error triggers
// and matches each captured response against its fixture in
// ../contract-fixtures/ (the same files the Dart client's
// contract_fixtures_test.dart consumes). A field renamed/removed/added on the
// server — or in a fixture — fails this suite and the Dart one.

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import { createApp, currentUtcDateOnly } from './harness.mjs';

const fixturesDir = new URL('../contract-fixtures/', import.meta.url);
function fixture(name) {
  return JSON.parse(readFileSync(new URL(`${name}.json`, fixturesDir), 'utf8'));
}

// Structural match, mirroring the Dart consumer: <string>/<int>/<iso>/<url>
// tokens match by type; objects must have the exact key set; everything else
// (protocol constants like result/reason/code, booleans, fixed numbers)
// matches exactly.
function matchFixture(actual, expected, path = '$') {
  if (
    typeof expected === 'string' &&
    expected.startsWith('<') &&
    expected.endsWith('>')
  ) {
    switch (expected) {
      case '<string>':
        assert.equal(typeof actual, 'string', `${path}: expected string`);
        return;
      case '<int>':
        assert.ok(Number.isInteger(actual), `${path}: expected int, got ${actual}`);
        return;
      case '<iso>':
        assert.equal(typeof actual, 'string', `${path}: expected iso string`);
        assert.ok(!Number.isNaN(Date.parse(actual)), `${path}: not an ISO datetime`);
        return;
      case '<url>':
        assert.equal(typeof actual, 'string', `${path}: expected url string`);
        assert.ok(actual.startsWith('http'), `${path}: not a url`);
        return;
      default:
        throw new Error(`${path}: unknown placeholder token ${expected}`);
    }
  }
  if (Array.isArray(expected)) {
    assert.ok(Array.isArray(actual), `${path}: expected array`);
    assert.equal(actual.length, expected.length, `${path}: array length`);
    expected.forEach((e, i) => matchFixture(actual[i], e, `${path}[${i}]`));
    return;
  }
  if (expected && typeof expected === 'object') {
    assert.ok(actual && typeof actual === 'object', `${path}: expected object`);
    assert.deepEqual(
      Object.keys(actual).sort(),
      Object.keys(expected).sort(),
      `${path}: key set differs`,
    );
    for (const key of Object.keys(expected)) {
      matchFixture(actual[key], expected[key], `${path}.${key}`);
    }
    return;
  }
  assert.deepEqual(actual, expected, `${path}`);
}

function matchResponse(actual, name) {
  matchFixture(actual, fixture(name).response.body, `${name}.response`);
}

const dailyMini = (over = {}) => ({
  sourceId: 'crosshare_daily_mini',
  sourcePuzzleId: '2026-06-05',
  completedAt: new Date().toISOString(),
  elapsedMs: 91000,
  completionType: 'clean',
  cleanSolveEligible: true,
  publishedOn: currentUtcDateOnly(),
  ...over,
});

test('contract: live responses match the shared fixtures (happy path)', async () => {
  const app = await createApp();

  const maya = await app.fetchJson('/players/bootstrap', {
    method: 'POST',
    body: { displayName: 'Maya' },
  });
  matchResponse(maya, 'players_bootstrap');

  matchResponse(
    await app.fetchJson('/players/me', { token: maya.authToken }),
    'players_me_get',
  );
  matchResponse(
    await app.fetchJson('/players/me', {
      method: 'PATCH',
      token: maya.authToken,
      body: { displayName: 'Maya' },
    }),
    'players_me_patch',
  );
  matchResponse(
    await app.fetchJson('/players/recovery/rotate', {
      method: 'POST',
      token: maya.authToken,
    }),
    'players_recovery_rotate',
  );

  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew', rankingMode: 'average_time' },
    status: 201,
  });
  matchResponse(created, 'boards_create');

  matchResponse(
    await app.fetchJson('/boards', { token: maya.authToken }),
    'boards_list',
  );

  // Single-player board → deterministic detail.
  matchResponse(
    await app.fetchJson(`/boards/${created.board.id}`, { token: maya.authToken }),
    'boards_detail',
  );

  const noah = await app.fetchJson('/players/bootstrap', {
    method: 'POST',
    body: { displayName: 'Noah' },
  });
  matchResponse(
    await app.fetchJson('/invites/preview', {
      method: 'POST',
      token: noah.authToken,
      body: { inviteLink: created.inviteLink },
    }),
    'invites_preview_valid',
  );
  matchResponse(
    await app.fetchJson('/invites/join', {
      method: 'POST',
      token: noah.authToken,
      body: { inviteLink: created.inviteLink },
    }),
    'invites_join',
  );

  matchResponse(
    await app.fetchJson(`/boards/${created.board.id}/invite/regenerate`, {
      method: 'POST',
      token: maya.authToken,
    }),
    'boards_invite_regenerate',
  );

  // Noah leaves; Maya remains, so the board is not deleted.
  matchResponse(
    await app.fetchJson(`/boards/${created.board.id}/leave`, {
      method: 'POST',
      token: noah.authToken,
    }),
    'boards_leave',
  );
});

test('contract: invalid invite preview matches the fixture', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  // A real board with a WRONG token previews as invalidOrExpired with no
  // details disclosed (#237). (A nonexistent board id would be boardDeleted.)
  const created = await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew', rankingMode: 'average_time' },
    status: 201,
  });
  const badLink = created.inviteLink.replace(/token=.*$/, 'token=wrong-secret');
  const noah = await app.bootstrap('Noah');
  matchResponse(
    await app.fetchJson('/invites/preview', {
      method: 'POST',
      token: noah.authToken,
      body: { inviteLink: badLink },
    }),
    'invites_preview_invalid',
  );
});

test('contract: result accept + every soft-reject match fixtures', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');

  // Before any board exists for the source.
  matchResponse(
    await app.fetchJson('/results', {
      method: 'POST',
      token: maya.authToken,
      status: 202,
      body: dailyMini(),
    }),
    'results_no_active_board',
  );

  await app.fetchJson('/boards', {
    method: 'POST',
    token: maya.authToken,
    body: { name: 'Friday Crew', rankingMode: 'average_time' },
    status: 201,
  });

  matchResponse(
    await app.fetchJson('/results', {
      method: 'POST',
      token: maya.authToken,
      status: 202,
      body: { sourceId: 'local_import', sourcePuzzleId: 'abc', completedAt: new Date().toISOString(), elapsedMs: 91000, completionType: 'clean', cleanSolveEligible: true },
    }),
    'results_not_daily_mini',
  );
  matchResponse(
    await app.fetchJson('/results', {
      method: 'POST',
      token: maya.authToken,
      status: 202,
      body: dailyMini({ elapsedMs: 1000 }),
    }),
    'results_implausible_elapsed',
  );
  matchResponse(
    await app.fetchJson('/results', {
      method: 'POST',
      token: maya.authToken,
      status: 202,
      body: dailyMini({
        completedAt: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
      }),
    }),
    'results_implausible_completed_at',
  );
  matchResponse(
    await app.fetchJson('/results', {
      method: 'POST',
      token: maya.authToken,
      status: 202,
      body: dailyMini({ puzzleTitle: 'Daily Mini' }),
    }),
    'results_accepted',
  );
});

test('contract: error envelopes match fixtures', async () => {
  const app = await createApp();

  matchResponse(
    await app.fetchJson('/boards', { status: 401 }),
    'error_unauthorized',
  );

  app.env.RL_IDENTITY = {
    async limit() {
      return { success: false };
    },
  };
  matchResponse(
    await app.fetchJson('/players/bootstrap', {
      method: 'POST',
      body: { displayName: 'Maya' },
      status: 429,
    }),
    'error_rate_limited',
  );
});

test('contract: player deletion matches the fixture', async () => {
  const app = await createApp();
  const maya = await app.bootstrap('Maya');
  matchResponse(
    await app.fetchJson('/players/me', { method: 'DELETE', token: maya.authToken }),
    'players_me_delete',
  );
});
