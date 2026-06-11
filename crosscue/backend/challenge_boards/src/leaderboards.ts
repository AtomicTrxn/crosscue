// Weekly/lifetime aggregation, ranking, and leaderboard serialization.

import { serializePlayer } from "./players.ts";
import type { BoardRow, Env, JsonValue, LeaderboardRow, PlayerRow, RankingMode } from "./types.ts";
import { currentUtcWeekRange, formatMs } from "./util.ts";

export async function boardLeaderboard(
  env: Env,
  board: BoardRow,
  mode: "weekly" | "lifetime",
): Promise<LeaderboardRow[]> {
  const byBoard = await boardLeaderboards(env, [board], mode);
  return byBoard.get(board.id) ?? [];
}

// Aggregates every requested board in one query: listing five boards used to
// run five full leaderboard aggregations (review finding 14).

// Aggregates every requested board in one query: listing five boards used to
// run five full leaderboard aggregations (review finding 14).
export async function boardLeaderboards(
  env: Env,
  boards: BoardRow[],
  mode: "weekly" | "lifetime",
): Promise<Map<string, LeaderboardRow[]>> {
  const byBoard = new Map<string, LeaderboardRow[]>();
  if (boards.length === 0) return byBoard;
  const week = currentUtcWeekRange();
  const where =
    mode === "weekly"
      ? "and r.published_on >= ? and r.published_on < ?"
      : "";
  const weekParams =
    mode === "weekly" ? [week.startDate, week.endDate] : [];
  const placeholders = boards.map(() => "?").join(",");
  const rows = await env.DB.prepare(
    `select m.board_id, p.id, m.display_name, p.avatar_kind,
            p.avatar_silhouette_look, p.avatar_photo_url,
            coalesce(sum(case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then 1 else 0 end), 0) as cleanSolves,
            avg(case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then r.elapsed_ms else null end) as avgCleanMs,
            min(case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then r.elapsed_ms else null end) as bestCleanMs,
            sum(case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then r.elapsed_ms else null end) as totalCleanMs,
            count(r.id) as submittedCount,
            coalesce(sum(case
              when r.id is not null
               and not (r.completion_type = 'clean'
                and r.clean_solve_eligible = 1)
              then 1 else 0 end), 0) as assistedCount,
            count(distinct case
              when r.completion_type = 'clean'
               and r.clean_solve_eligible = 1
              then date(
                r.completed_at,
                '-' || ((cast(strftime('%w', r.completed_at) as integer) + 6) % 7) || ' days'
              )
              else null end) as weeksCounted
     from memberships m
     join boards b on b.id = m.board_id
     join players p on p.id = m.player_id
     left join challenge_results r on r.player_id = m.player_id
       and r.source_id = b.source_id ${where}
     where m.board_id in (${placeholders}) and m.left_at is null
     group by m.board_id, p.id, m.display_name, p.avatar_kind,
              p.avatar_silhouette_look, p.avatar_photo_url, m.joined_at
     order by m.board_id, m.joined_at asc`,
  )
    .bind(...weekParams, ...boards.map((board) => board.id))
    .all<PlayerRow & {
      board_id: string;
      cleanSolves: number;
      avgCleanMs: number | null;
      bestCleanMs: number | null;
      totalCleanMs: number | null;
      weeksCounted: number;
      submittedCount: number;
      assistedCount: number;
    }>();

  for (const board of boards) byBoard.set(board.id, []);
  for (const row of rows.results) {
    byBoard.get(row.board_id)?.push({
      player: {
        id: row.id,
        display_name: row.display_name,
        avatar_kind: row.avatar_kind,
        avatar_silhouette_look: row.avatar_silhouette_look,
        avatar_photo_url: row.avatar_photo_url,
      },
      cleanSolves: Number(row.cleanSolves ?? 0),
      avgCleanMs: row.avgCleanMs == null ? null : Number(row.avgCleanMs),
      bestCleanMs: row.bestCleanMs == null ? null : Number(row.bestCleanMs),
      totalCleanMs: row.totalCleanMs == null ? null : Number(row.totalCleanMs),
      weeksCounted: Number(row.weeksCounted ?? 0),
      submittedCount: Number(row.submittedCount ?? 0),
      assistedCount: Number(row.assistedCount ?? 0),
    });
  }

  for (const board of boards) {
    const entries = byBoard.get(board.id) ?? [];
    const rankingMode = board.ranking_mode ?? "average_time";
    entries.sort((a, b) => compareLeaderboardRows(a, b, rankingMode));
    entries.forEach((entry, index) => {
      entry.rank = index + 1;
    });
  }
  return byBoard;
}

export async function lifetimeStats(env: Env, playerId: string): Promise<JsonValue> {
  const row = await env.DB.prepare(
    `select count(*) as cleanSolves,
            avg(elapsed_ms) as avgCleanMs,
            min(elapsed_ms) as bestCleanMs,
            count(distinct date(
              completed_at,
              '-' || ((cast(strftime('%w', completed_at) as integer) + 6) % 7) || ' days'
            )) as weeksCounted
     from challenge_results
     where player_id = ?
       and completion_type = 'clean'
       and clean_solve_eligible = 1`,
  )
    .bind(playerId)
    .first<{
      cleanSolves: number;
      avgCleanMs: number | null;
      bestCleanMs: number | null;
      weeksCounted: number;
    }>();

  const cleanSolves = Number(row?.cleanSolves ?? 0);
  return {
    avgClean: formatMs(row?.avgCleanMs ?? null),
    cleanSolves,
    bestClean: formatMs(row?.bestCleanMs ?? null),
    rankingStatus:
      cleanSolves >= 5
        ? `Ranked across ${Number(row?.weeksCounted ?? 0)} UTC weeks`
        : "Solve 5 clean puzzles to unlock lifetime ranking",
    weeksCounted: Number(row?.weeksCounted ?? 0),
  };
}

export function compareLeaderboardRows(
  a: LeaderboardRow,
  b: LeaderboardRow,
  rankingMode: RankingMode,
): number {
  if (a.cleanSolves === 0 && b.cleanSolves > 0) return 1;
  if (a.cleanSolves > 0 && b.cleanSolves === 0) return -1;
  const aMetric = rankingMetric(a, rankingMode);
  const bMetric = rankingMetric(b, rankingMode);
  if (aMetric == null && bMetric != null) return 1;
  if (aMetric != null && bMetric == null) return -1;
  if (aMetric != null && bMetric != null && aMetric !== bMetric) {
    return aMetric - bMetric;
  }
  if (b.cleanSolves !== a.cleanSolves) return b.cleanSolves - a.cleanSolves;
  if (b.assistedCount !== a.assistedCount) {
    return b.assistedCount - a.assistedCount;
  }
  return a.player.display_name.localeCompare(b.player.display_name);
}

export function rankingMetric(
  entry: LeaderboardRow,
  rankingMode: RankingMode,
): number | null {
  if (entry.cleanSolves === 0) return null;
  if (rankingMode === "fastest_time") return entry.bestCleanMs;
  if (rankingMode === "total_time") return entry.totalCleanMs;
  return entry.avgCleanMs;
}

export function serializeBoardSummary(
  board: BoardRow,
  standing?: LeaderboardRow,
): JsonValue {
  const count = Number(board.player_count ?? 1);
  return {
    id: board.id,
    name: board.name,
    playerCount: count,
    rankingMode: board.ranking_mode ?? "average_time",
    ownerPlayerId: board.owner_player_id ?? null,
    myWeekly: {
      rank: standing?.rank ?? count,
      outOf: count,
      cleanSolves: standing?.cleanSolves ?? 0,
      avgClean: formatMs(standing?.avgCleanMs ?? null),
      bestClean: formatMs(standing?.bestCleanMs ?? null),
      totalClean: formatMs(standing?.totalCleanMs ?? null),
    },
  };
}

export function serializeLeaderboardEntry(
  entry: LeaderboardRow,
  currentPlayerId: string,
): JsonValue {
  return {
    rank: entry.rank ?? 1,
    player: serializePlayer(entry.player, entry.player.id === currentPlayerId),
    cleanSolves: entry.cleanSolves,
    avgClean: formatMs(entry.avgCleanMs),
    bestClean: formatMs(entry.bestCleanMs),
    totalClean: formatMs(entry.totalCleanMs),
    weeksCounted: entry.weeksCounted,
  };
}

export function emptyLifetime(): JsonValue {
  return {
    avgClean: "—",
    cleanSolves: 0,
    bestClean: "—",
    rankingStatus: "Solve 5 clean puzzles to unlock lifetime ranking",
    weeksCounted: 0,
  };
}
