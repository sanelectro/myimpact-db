ALTER TABLE goal_source_retrievals
    ADD COLUMN outcome VARCHAR(24) NOT NULL DEFAULT 'COMPLETE';

ALTER TABLE goal_source_retrievals
    ADD COLUMN error_category VARCHAR(40);

ALTER TABLE goal_source_retrievals
    ADD COLUMN attempted_at TIMESTAMPTZ;

ALTER TABLE goal_source_retrievals
    ADD COLUMN last_verified_at TIMESTAMPTZ;

ALTER TABLE goal_source_retrievals
    ADD COLUMN last_retrieved_at TIMESTAMPTZ;

ALTER TABLE goal_source_retrievals
    ADD COLUMN retry_count INTEGER NOT NULL DEFAULT 0;

ALTER TABLE goal_source_retrievals
    ADD COLUMN bounds JSONB;

ALTER TABLE goal_source_retrievals
    ADD COLUMN coverage JSONB;

ALTER TABLE goal_source_retrievals
    ADD CONSTRAINT ck_goal_source_retrieval_outcome
    CHECK (outcome IN ('COMPLETE', 'PARTIAL', 'NO_RESULTS', 'INACCESSIBLE', 'FAILED'));
