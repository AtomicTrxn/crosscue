-- Operational metadata (#262). A tiny key/value table for liveness signals.
-- Additive and backward-compatible with the currently deployed Worker.
create table if not exists ops_meta (
  key text primary key,
  value text not null
);
