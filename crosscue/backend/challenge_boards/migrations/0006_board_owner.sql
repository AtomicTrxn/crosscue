-- Board ownership: the creator owns the board until they depart, then
-- ownership passes to the earliest-joined active member (succession is
-- implemented in the Worker; this migration adds the column and backfills).
ALTER TABLE boards ADD COLUMN owner_player_id TEXT;

-- Backfill: the creator if they are still an active member, otherwise the
-- earliest-joined active member (a board whose creator already left must not
-- end up with an absent owner). Boards with no active members are already
-- soft-deleted and keep NULL.
UPDATE boards SET owner_player_id = COALESCE(
  (SELECT m.player_id FROM memberships m
    WHERE m.board_id = boards.id
      AND m.player_id = boards.created_by_player_id
      AND m.left_at IS NULL),
  (SELECT m.player_id FROM memberships m
    WHERE m.board_id = boards.id AND m.left_at IS NULL
    ORDER BY m.joined_at, m.player_id LIMIT 1));
