-- Retention index for the daily board_events purge (#159 workstream C).
create index if not exists idx_board_events_retention
  on board_events(created_at);
