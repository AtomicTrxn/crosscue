// Shared in-memory test harness for the Worker suite (worker.test.mjs) and the
// contract-fixture suite (contract.test.mjs). Drives the real Worker against a
// node:sqlite-backed D1 shim; optional R2 shim for avatar tests.

import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

import worker from '../src/index.ts';

export const apiBase = 'https://challenge.test';

export function currentUtcDateOnly() {
  return new Date().toISOString().slice(0, 10);
}

export async function createApp(envOverrides = {}) {
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
export class R2BucketShim {
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
