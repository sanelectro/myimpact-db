\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
    IF current_database() <> 'hierarchytest' THEN
        RAISE EXCEPTION 'This test must run against the disposable hierarchytest database';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM goal_versions
        WHERE id = 'phase1-upgrade-version'
          AND definition_kind = 'STANDARD'
          AND content->>'title' = 'Existing goal'
    ) THEN
        RAISE EXCEPTION 'Existing versions must retain their content and standard classification';
    END IF;
END $$;

INSERT INTO goal_versions (id, goal_id, version, origin, definition_kind, content, created_at)
VALUES ('phase1-proposal-version', 'phase1-upgrade-goal', 2, 'USER', 'PROPOSAL',
        '{"title":"Candidate"}', now());

DO $$
BEGIN
    BEGIN
        INSERT INTO goal_versions (id, goal_id, version, origin, definition_kind, content, created_at)
        VALUES ('phase1-invalid-kind', 'phase1-upgrade-goal', 3, 'USER', 'INVALID', '{}', now());
        RAISE EXCEPTION 'Expected invalid definition kind to fail';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        UPDATE goal_versions SET definition_kind = 'STANDARD' WHERE id = 'phase1-proposal-version';
        RAISE EXCEPTION 'Expected immutable proposal classification';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM <> 'Goal versions and validation runs are immutable' THEN RAISE; END IF;
    END;
    IF (SELECT operative_goal_version_id FROM goals WHERE id = 'phase1-upgrade-goal') IS NOT NULL
       OR (SELECT title FROM goals WHERE id = 'phase1-upgrade-goal') <> 'Existing goal' THEN
        RAISE EXCEPTION 'Inserting a proposal must not modify the current goal';
    END IF;
END $$;

ROLLBACK;
