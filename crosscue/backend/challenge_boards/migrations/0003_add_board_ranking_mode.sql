-- No-op. boards.ranking_mode is defined directly in 0001_core_membership.sql.
-- This migration originally added the column, but the fresh schema in 0001 was
-- later consolidated to include it, which made applying both fail on a clean
-- database with "duplicate column name: ranking_mode". Kept as a no-op (rather
-- than deleted) so the migration sequence and already-applied history stay
-- intact for environments that ran the original ALTER.
select 1;
