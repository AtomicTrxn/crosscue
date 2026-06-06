alter table boards
  add column ranking_mode text not null default 'average_time' check (
    ranking_mode in ('fastest_time', 'average_time', 'total_time')
  );
