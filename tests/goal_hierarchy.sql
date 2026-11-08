\set ON_ERROR_STOP on
BEGIN;

INSERT INTO users (id, name, email, created_at, updated_at)
VALUES ('hierarchy-test-owner', 'Owner', 'hierarchy-test-owner@example.test', now(), now()),
       ('hierarchy-test-other', 'Other', 'hierarchy-test-other@example.test', now(), now());
INSERT INTO goals (id, user_id, title, status, created_at, updated_at)
VALUES ('hierarchy-test-a', 'hierarchy-test-owner', 'A', 'DRAFT', now(), now()),
       ('hierarchy-test-b', 'hierarchy-test-owner', 'B', 'DRAFT', now(), now()),
       ('hierarchy-test-c', 'hierarchy-test-owner', 'C', 'DRAFT', now(), now()),
       ('hierarchy-test-other', 'hierarchy-test-other', 'Other', 'DRAFT', now(), now());

DO $$
BEGIN
    BEGIN
        UPDATE goals SET parent_goal_id = 'hierarchy-test-b' WHERE id = 'hierarchy-test-a';
        RAISE EXCEPTION 'Expected missing lock to fail';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM NOT LIKE 'Acquire the hierarchy%' THEN RAISE; END IF;
    END;
END $$;

SELECT pg_advisory_xact_lock(1296650324, 1);
DO $$
BEGIN
    BEGIN
        UPDATE goals SET parent_goal_id = 'hierarchy-test-b' WHERE id = 'hierarchy-test-a';
        RAISE EXCEPTION 'Expected missing actor to fail';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM <> 'Hierarchy actor must be the goal owner' THEN RAISE; END IF;
    END;
END $$;
SELECT set_config('myimpact.relationship_actor', 'hierarchy-test-owner', true);
SELECT set_config('myimpact.relationship_reason', 'test relationship', true);
UPDATE goals SET parent_goal_id = 'hierarchy-test-b' WHERE id = 'hierarchy-test-a';
UPDATE goals SET parent_goal_id = 'hierarchy-test-c' WHERE id = 'hierarchy-test-b';
UPDATE goals SET parent_goal_id = 'hierarchy-test-b' WHERE id = 'hierarchy-test-a';

DO $$
BEGIN
    BEGIN
        UPDATE goals SET parent_goal_id = 'hierarchy-test-c' WHERE id = 'hierarchy-test-c';
        RAISE EXCEPTION 'Expected self-parenting to fail';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM <> 'Goal hierarchy cannot contain cycles' THEN RAISE; END IF;
    END;
    BEGIN
        UPDATE goals SET goal_level = 'WEEKLY' WHERE id = 'hierarchy-test-a';
        RAISE EXCEPTION 'Expected invalid level to fail';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    IF (SELECT relationship_revision FROM goals WHERE id = 'hierarchy-test-a') <> 1
       OR (SELECT count(*) FROM goal_relationship_events WHERE goal_id = 'hierarchy-test-a') <> 1 THEN
        RAISE EXCEPTION 'Same-parent update must be idempotent';
    END IF;
    BEGIN
        UPDATE goals SET parent_goal_id = 'hierarchy-test-a' WHERE id = 'hierarchy-test-c';
        RAISE EXCEPTION 'Expected cycle to fail';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM <> 'Goal hierarchy cannot contain cycles' THEN RAISE; END IF;
    END;
    BEGIN
        UPDATE goals SET parent_goal_id = 'hierarchy-test-other' WHERE id = 'hierarchy-test-a';
        RAISE EXCEPTION 'Expected cross-owner parent to fail';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        DELETE FROM goals WHERE id = 'hierarchy-test-b';
        RAISE EXCEPTION 'Expected parent deletion to fail';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        UPDATE goal_relationship_events SET reason = 'modified' WHERE goal_id = 'hierarchy-test-a';
        RAISE EXCEPTION 'Expected history mutation to fail';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM <> 'Goal relationship events are append-only' THEN RAISE; END IF;
    END;
END $$;

UPDATE goals SET parent_goal_id = NULL WHERE id = 'hierarchy-test-a';
UPDATE goals SET parent_goal_id = 'hierarchy-test-c' WHERE id = 'hierarchy-test-a';
DO $$
BEGIN
    IF (SELECT relationship_revision FROM goals WHERE id = 'hierarchy-test-a') <> 3
       OR NOT EXISTS (
           SELECT 1 FROM goal_relationship_events
           WHERE goal_id = 'hierarchy-test-a' AND old_parent_goal_id = 'hierarchy-test-b'
             AND new_parent_goal_id IS NULL AND actor_user_id = 'hierarchy-test-owner'
             AND reason = 'test relationship' AND relationship_revision = 2
       ) THEN
        RAISE EXCEPTION 'Disconnect history is incorrect';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM goal_relationship_events WHERE goal_id = 'hierarchy-test-a'
          AND old_parent_goal_id IS NULL AND new_parent_goal_id = 'hierarchy-test-c'
          AND relationship_revision = 3
    ) THEN
        RAISE EXCEPTION 'Reconnect history is incorrect';
    END IF;
END $$;
ROLLBACK;
