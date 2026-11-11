\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
    IF current_database() <> 'hierarchytest' THEN
        RAISE EXCEPTION 'This test must run against the disposable hierarchytest database';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM goals
        WHERE id = 'phase1-upgrade-goal'
          AND title = 'Existing goal'
          AND status = 'ACTIVE'
          AND operative_goal_version_id IS NULL
    ) OR NOT EXISTS (
        SELECT 1 FROM goal_versions
        WHERE id = 'phase1-upgrade-version'
          AND goal_id = 'phase1-upgrade-goal'
          AND content->>'title' = 'Existing goal'
    ) THEN
        RAISE EXCEPTION 'Migration must preserve the existing goal without guessing its operative version';
    END IF;
END $$;

INSERT INTO users (id, name, email, created_at, updated_at)
VALUES ('phase1-owner', 'Owner', 'phase1-owner@example.test', now(), now());
INSERT INTO goals (id, user_id, title, status, created_at, updated_at)
VALUES ('phase1-goal-a', 'phase1-owner', 'A', 'DRAFT', now(), now()),
       ('phase1-goal-b', 'phase1-owner', 'B', 'DRAFT', now(), now());
INSERT INTO goal_versions (id, goal_id, version, origin, content, created_at)
VALUES ('phase1-version-a1', 'phase1-goal-a', 1, 'USER', '{"title":"A"}', now()),
       ('phase1-version-a2', 'phase1-goal-a', 2, 'USER', '{"title":"Proposed"}', now()),
       ('phase1-version-b1', 'phase1-goal-b', 1, 'USER', '{"title":"B"}', now());

DO $$
BEGIN
    IF (SELECT operative_goal_version_id FROM goals WHERE id = 'phase1-goal-a') IS NOT NULL THEN
        RAISE EXCEPTION 'Creating versions must not automatically select one';
    END IF;
END $$;

UPDATE goals SET operative_goal_version_id = 'phase1-version-a1' WHERE id = 'phase1-goal-a';
SET CONSTRAINTS fk_goals_operative_version_goal IMMEDIATE;
DO $$
BEGIN
    BEGIN
        UPDATE goals SET operative_goal_version_id = 'phase1-version-b1' WHERE id = 'phase1-goal-a';
        RAISE EXCEPTION 'Expected cross-goal selection to fail';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        UPDATE goals SET operative_goal_version_id = 'phase1-missing-version' WHERE id = 'phase1-goal-a';
        RAISE EXCEPTION 'Expected missing version selection to fail';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    IF (SELECT operative_goal_version_id FROM goals WHERE id = 'phase1-goal-a') <> 'phase1-version-a1'
       OR (SELECT title FROM goals WHERE id = 'phase1-goal-a') <> 'A' THEN
        RAISE EXCEPTION 'Rejected selections must preserve the original goal';
    END IF;
END $$;

DO $$
BEGIN
    BEGIN
        UPDATE goals SET operative_goal_version_id = 'phase1-version-a2' WHERE id = 'phase1-goal-a';
        RAISE EXCEPTION 'Force rollback of candidate selection';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM <> 'Force rollback of candidate selection' THEN RAISE; END IF;
    END;
    IF (SELECT operative_goal_version_id FROM goals WHERE id = 'phase1-goal-a') <> 'phase1-version-a1' THEN
        RAISE EXCEPTION 'A rolled-back selection must leave the previous version selected';
    END IF;
END $$;

SET CONSTRAINTS fk_goals_operative_version_goal DEFERRED;
UPDATE goals SET operative_goal_version_id = 'phase1-version-b1' WHERE id = 'phase1-goal-b';
DELETE FROM goals WHERE id = 'phase1-goal-b';
SET CONSTRAINTS fk_goals_operative_version_goal IMMEDIATE;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM goals WHERE id = 'phase1-goal-b')
       OR EXISTS (SELECT 1 FROM goal_versions WHERE id = 'phase1-version-b1') THEN
        RAISE EXCEPTION 'Existing cascading deletion behavior must remain unchanged';
    END IF;
END $$;

ROLLBACK;
