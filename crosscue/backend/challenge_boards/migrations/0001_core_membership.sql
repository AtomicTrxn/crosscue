pragma foreign_keys = on;

create table if not exists players (
  id text primary key,
  display_name text not null,
  auth_token_hash text not null,
  avatar_kind text not null default 'initials',
  avatar_silhouette_look integer not null default 1,
  avatar_photo_url text,
  created_at text not null,
  last_seen_at text not null,
  deleted_at text
);

create table if not exists boards (
  id text primary key,
  name text not null,
  source_id text not null,
  invite_code_hash text not null,
  invite_version integer not null default 1,
  invite_expires_at text not null,
  invite_rotated_at text not null,
  invite_rotated_by_player_id text references players(id),
  created_by_player_id text not null references players(id),
  created_at text not null,
  deleted_at text
);

create table if not exists memberships (
  board_id text not null references boards(id),
  player_id text not null references players(id),
  display_name text not null,
  joined_at text not null,
  left_at text,
  membership_state text not null default 'active',
  primary key (board_id, player_id)
);

create table if not exists board_events (
  id text primary key,
  board_id text not null references boards(id),
  actor_player_id text references players(id),
  event_type text not null,
  event_payload_json text,
  created_at text not null
);

create index if not exists idx_memberships_player_active
  on memberships(player_id)
  where left_at is null;

create index if not exists idx_memberships_board_active
  on memberships(board_id)
  where left_at is null;

create index if not exists idx_board_events_board_created
  on board_events(board_id, created_at);
