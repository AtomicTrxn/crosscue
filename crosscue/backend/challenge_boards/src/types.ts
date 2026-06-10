// Shared row, payload, and environment types.

export interface Env {
  DB: D1Database;
  PUBLIC_APP_URL: string;
  APP_ENV: string;
  // Cloudflare Rate Limiting bindings. Optional so local/test runs without the
  // bindings configured skip limiting rather than crashing.
  RL_IDENTITY?: RateLimiter;
  RL_WRITE?: RateLimiter;
}

export interface RateLimiter {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}

export type JsonValue =
  | null
  | boolean
  | number
  | string
  | JsonValue[]
  | { [key: string]: JsonValue };

export type PlayerRow = {
  id: string;
  display_name: string;
  avatar_kind: string;
  avatar_silhouette_look: number;
  avatar_photo_url: string | null;
};

export type BoardRow = {
  id: string;
  name: string;
  source_id: string;
  ranking_mode?: RankingMode;
  invite_expires_at: string;
  invite_version: number;
  player_count?: number;
  deleted_at?: string | null;
};

export type RankingMode = "fastest_time" | "average_time" | "total_time";

export type Auth = {
  player: PlayerRow;
  tokenHash: string;
};

export type LeaderboardRow = {
  rank?: number;
  player: PlayerRow;
  cleanSolves: number;
  avgCleanMs: number | null;
  bestCleanMs: number | null;
  totalCleanMs: number | null;
  weeksCounted: number;
  submittedCount: number;
  assistedCount: number;
};
