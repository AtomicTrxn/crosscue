-- Anonymous player recovery bundle support (#159 workstream A).
-- The backend stores only hash(recoverySecret); the raw secret lives in the
-- client's private app-storage recovery bundle and is exchanged at /players/restore.
alter table players add column recovery_secret_hash text;
alter table players add column recovery_secret_rotated_at text;
