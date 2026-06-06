create table if not exists challenge_results (
  id text primary key,
  player_id text not null references players(id),
  source_id text not null,
  source_puzzle_id text not null,
  puzzle_title text,
  published_on text,
  completed_at text not null,
  elapsed_ms integer not null,
  completion_type text not null check (
    completion_type in ('clean', 'checked', 'hinted', 'revealed', 'unsolved')
  ),
  clean_solve_eligible integer not null default 0,
  created_at text not null,
  updated_at text not null,
  unique(player_id, source_id, source_puzzle_id)
);

create index if not exists idx_challenge_results_source_completed
  on challenge_results(source_id, completed_at);

create index if not exists idx_challenge_results_player_source
  on challenge_results(player_id, source_id);
