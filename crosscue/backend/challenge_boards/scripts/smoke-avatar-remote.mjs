const rawBaseUrl = process.env.CHALLENGE_API_BASE_URL?.trim();
if (!rawBaseUrl) {
  throw new Error(
    'CHALLENGE_API_BASE_URL is required (use the staging or production Worker URL).',
  );
}

const baseUrl = new URL(rawBaseUrl);
if (baseUrl.protocol !== 'https:') {
  throw new Error(
    'CHALLENGE_API_BASE_URL must use HTTPS for a remote smoke test.',
  );
}
const basePath = baseUrl.pathname.replace(/\/+$/u, '');
baseUrl.search = '';
baseUrl.hash = '';

const requestTimeoutMs = 20_000;
const clientIdentity = 'smoke/999.0.0';
const pngBase64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8' +
  '/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
const expectedPng = Buffer.from(pngBase64, 'base64');
const pngMagic = Buffer.from([
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
]);

function apiUrl(path) {
  const url = new URL(baseUrl.origin);
  url.pathname = `${basePath}${path}`;
  return url;
}

async function readResponseText(response) {
  const text = await response.text();
  return text.length <= 2_000 ? text : `${text.slice(0, 2_000)}…`;
}

async function requestJson(path, options = {}) {
  const headers = {
    'content-type': 'application/json',
    'x-crosscue-client': clientIdentity,
  };
  if (options.authToken) {
    headers.authorization = `Bearer ${options.authToken}`;
  }

  const response = await fetch(apiUrl(path), {
    method: options.method ?? 'GET',
    headers,
    body: options.body == null ? undefined : JSON.stringify(options.body),
    redirect: 'error',
    signal: AbortSignal.timeout(requestTimeoutMs),
  });
  const expectedStatus = options.status ?? 200;
  const text = await readResponseText(response);
  if (response.status !== expectedStatus) {
    throw new Error(
      `${options.method ?? 'GET'} ${path} expected ${expectedStatus}, got ${response.status}: ${text}`,
    );
  }
  try {
    return text ? JSON.parse(text) : null;
  } catch {
    throw new Error(
      `${options.method ?? 'GET'} ${path} returned invalid JSON.`,
    );
  }
}

async function fetchAvatar(photoUrl, expectedStatus) {
  const response = await fetch(photoUrl, {
    redirect: 'error',
    signal: AbortSignal.timeout(requestTimeoutMs),
  });
  if (response.status !== expectedStatus) {
    const text = await readResponseText(response);
    throw new Error(
      `GET avatar expected ${expectedStatus}, got ${response.status}: ${text}`,
    );
  }
  return response;
}

let authToken;
let photoUrl;
let failure;
try {
  const bootstrap = await requestJson('/players/bootstrap', {
    method: 'POST',
    body: { displayName: 'R2Smoke' },
  });
  authToken = bootstrap?.authToken;
  if (typeof authToken !== 'string' || authToken.length === 0) {
    throw new Error('Bootstrap response did not include an auth token.');
  }

  const updated = await requestJson('/players/me/avatar', {
    method: 'POST',
    authToken,
    body: { kind: 'photo', photoPngBase64: pngBase64 },
  });
  photoUrl = updated?.player?.avatar?.photoUrl;
  if (typeof photoUrl !== 'string' || photoUrl.startsWith('data:')) {
    throw new Error('Avatar upload did not return an R2-backed URL.');
  }

  const parsedPhotoUrl = new URL(photoUrl);
  if (
    parsedPhotoUrl.protocol !== 'https:' ||
    parsedPhotoUrl.origin !== baseUrl.origin ||
    !/^\/avatars\/[^/]+\/[a-f0-9]{64}\.png$/u.test(parsedPhotoUrl.pathname)
  ) {
    throw new Error('Avatar upload returned an unexpected URL shape or origin.');
  }

  const imageResponse = await fetchAvatar(photoUrl, 200);
  const contentType = imageResponse.headers.get('content-type') ?? '';
  if (!contentType.toLowerCase().startsWith('image/png')) {
    throw new Error(
      `Avatar response content-type was ${contentType || 'missing'}.`,
    );
  }
  const cacheControl = imageResponse.headers.get('cache-control') ?? '';
  if (!/\bimmutable\b/iu.test(cacheControl)) {
    throw new Error('Avatar response is missing immutable cache metadata.');
  }

  const imageBytes = Buffer.from(await imageResponse.arrayBuffer());
  if (
    imageBytes.length !== expectedPng.length ||
    !imageBytes.subarray(0, pngMagic.length).equals(pngMagic) ||
    !imageBytes.equals(expectedPng)
  ) {
    throw new Error('Avatar response bytes did not match the uploaded PNG.');
  }
} catch (error) {
  failure = error;
} finally {
  if (authToken) {
    try {
      await requestJson('/players/me', {
        method: 'DELETE',
        authToken,
      });
      if (photoUrl) {
        await fetchAvatar(photoUrl, 404);
      }
    } catch (cleanupError) {
      failure = failure
        ? new AggregateError(
            [failure, cleanupError],
            'Avatar smoke test and cleanup both failed.',
          )
        : cleanupError;
    }
  }
}

if (failure) throw failure;

console.log(
  JSON.stringify({
    ok: true,
    origin: baseUrl.origin,
    storage: 'r2',
    uploadedBytes: expectedPng.length,
    cleanup: 'player-and-avatar-deleted',
  }),
);
