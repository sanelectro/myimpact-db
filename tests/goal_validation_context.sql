\set ON_ERROR_STOP on
BEGIN;
INSERT INTO users (id, name, email, created_at, updated_at)
VALUES ('validation-test-owner', 'Owner', 'validation-test-owner@example.test', now(), now());
INSERT INTO goals (id, user_id, title, status, created_at, updated_at)
VALUES ('validation-test-goal', 'validation-test-owner', 'Goal', 'DRAFT', now(), now());
INSERT INTO goal_versions (id, goal_id, version, origin, content, created_at)
VALUES ('validation-test-version', 'validation-test-goal', 1, 'USER', '{}', now());
INSERT INTO goal_validation_runs
    (id, goal_id, goal_version_id, status, findings, input_context, result_context,
     rule_set_version, prompt_version, created_at)
VALUES
    ('validation-test-run', 'validation-test-goal', 'validation-test-version', 'READY', '[]',
     '{"deferred_requirements":[{"requirement":"target","reason":"Planning"}]}',
     '{"requirements":[{"requirement":"target","state":"DEFERRED"}]}',
     'goal-rules-v2', 'goal-semantic-validation-v3', now());
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM goal_validation_runs WHERE id = 'validation-test-run'
          AND input_context #>> '{deferred_requirements,0,reason}' = 'Planning'
          AND result_context #>> '{requirements,0,state}' = 'DEFERRED'
    ) THEN
        RAISE EXCEPTION 'Validation context was not stored';
    END IF;
    BEGIN
        UPDATE goal_validation_runs SET result_context = '{}' WHERE id = 'validation-test-run';
        RAISE EXCEPTION 'Expected immutable history';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM <> 'Goal versions and validation runs are immutable' THEN RAISE; END IF;
    END;
END $$;
ROLLBACK;
