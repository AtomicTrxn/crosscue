const base = process.env.CHALLENGE_API_BASE_URL ?? 'http://127.0.0.1:8787';

async function request(path, options = {}) {
  const headers = { 'content-type': 'application/json' };
  if (options.token) headers.authorization = `Bearer ${options.token}`;
  const response = await fetch(`${base}${path}`, {
    method: options.method ?? 'GET',
    headers,
    body: options.body == null ? undefined : JSON.stringify(options.body),
  });
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;
  const expected = options.status ?? 200;
  if (response.status !== expected) {
    throw new Error(
      `${options.method ?? 'GET'} ${path} expected ${expected}, got ${response.status}: ${text}`,
    );
  }
  return data;
}

const sourcePuzzleId = `smoke-${Date.now()}`;
const maya = await request('/players/bootstrap', {
  method: 'POST',
  body: { displayName: 'Maya' },
});
const noah = await request('/players/bootstrap', {
  method: 'POST',
  body: { displayName: 'Noah' },
});
const created = await request('/boards', {
  method: 'POST',
  token: maya.authToken,
  status: 201,
  body: { name: 'Friday Crew' },
});
const preview = await request('/invites/preview', {
  method: 'POST',
  token: noah.authToken,
  body: { inviteLink: created.inviteLink },
});
if (preview.invite.result !== 'valid') {
  throw new Error(`Expected valid invite preview, got ${preview.invite.result}`);
}

await request('/invites/join', {
  method: 'POST',
  token: noah.authToken,
  body: { inviteLink: created.inviteLink },
});

const completedAt = new Date().toISOString();
const publishedOn = completedAt.slice(0, 10);
await request('/results', {
  method: 'POST',
  token: maya.authToken,
  status: 202,
  body: {
    sourceId: 'crosshare_daily_mini',
    sourcePuzzleId,
    completedAt,
    elapsedMs: 91000,
    completionType: 'clean',
    cleanSolveEligible: true,
    puzzleTitle: 'Daily Mini',
    publishedOn,
  },
});
await request('/results', {
  method: 'POST',
  token: noah.authToken,
  status: 202,
  body: {
    sourceId: 'crosshare_daily_mini',
    sourcePuzzleId,
    completedAt,
    elapsedMs: 61000,
    completionType: 'checked',
    cleanSolveEligible: false,
    puzzleTitle: 'Daily Mini',
    publishedOn,
  },
});

const detail = await request(`/boards/${created.board.id}`, {
  token: maya.authToken,
});
const [first, second] = detail.weekly;
if (
  first?.player.displayName !== 'Maya' ||
  first.cleanSolves !== 1 ||
  second?.player.displayName !== 'Noah' ||
  second.cleanSolves !== 0
) {
  throw new Error(`Unexpected weekly ranking: ${JSON.stringify(detail.weekly)}`);
}

console.log(
  JSON.stringify(
    {
      ok: true,
      board: detail.board,
      weekly: detail.weekly.map((entry) => ({
        rank: entry.rank,
        name: entry.player.displayName,
        cleanSolves: entry.cleanSolves,
        avgClean: entry.avgClean,
      })),
    },
    null,
    2,
  ),
);
