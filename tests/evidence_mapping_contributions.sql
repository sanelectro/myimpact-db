\set ON_ERROR_STOP on
BEGIN;
INSERT INTO users (id, name, email, created_at, updated_at)
VALUES ('mapping-test-owner', 'Owner', 'mapping-test-owner@example.test', now(), now());
INSERT INTO goals (id, user_id, title, status, created_at, updated_at)
VALUES ('mapping-test-goal', 'mapping-test-owner', 'Goal', 'DRAFT', now(), now());
INSERT INTO evidence (id, user_id, source_type, title, captured_at, status, created_at, updated_at)
VALUES ('mapping-test-evidence', 'mapping-test-owner', 'PERSONAL', 'Evidence', now(), 'ACTIVE', now(), now());
INSERT INTO evidence_mappings (id, evidence_id, goal_id, relevance, confidence, created_at, updated_at)
VALUES ('mapping-test-id', 'mapping-test-evidence', 'mapping-test-goal', 'HIGH', 1, now(), now());
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM evidence_mappings WHERE id = 'mapping-test-id'
          AND mapping_kind = 'PRIMARY' AND contribution_description IS NULL
          AND created_by_user_id IS NULL
    ) THEN
        RAISE EXCEPTION 'Legacy mapping defaults were not preserved';
    END IF;
    BEGIN
        UPDATE evidence_mappings SET mapping_kind = 'INHERITED' WHERE id = 'mapping-test-id';
        RAISE EXCEPTION 'Expected invalid mapping kind to fail';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO evidence_mappings
            (id, evidence_id, goal_id, relevance, confidence, mapping_kind, created_at, updated_at)
        VALUES
            ('mapping-test-duplicate', 'mapping-test-evidence', 'mapping-test-goal', 'HIGH', 1,
             'CONTRIBUTION', now(), now());
        RAISE EXCEPTION 'Expected duplicate mapping to fail';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
END $$;
ROLLBACK;
