CREATE TABLE goal_source_retrievals (
    id VARCHAR(64) PRIMARY KEY,
    goal_id VARCHAR(64) NOT NULL,
    run_id VARCHAR(64) NOT NULL,
    provider VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    checked_at TIMESTAMPTZ NOT NULL,
    failure_reason TEXT,
    used_snapshot BOOLEAN NOT NULL DEFAULT FALSE,
    snapshot_captured_at TIMESTAMPTZ,
    CONSTRAINT ck_goal_source_retrieval_provider
        CHECK (provider IN ('github', 'jira')),
    CONSTRAINT ck_goal_source_retrieval_status
        CHECK (status IN ('SUCCESS', 'FAILURE')),
    CONSTRAINT fk_goal_source_retrievals_goal_id
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_source_retrievals_run_id
        FOREIGN KEY (run_id) REFERENCES goal_assessment_runs (id) ON DELETE CASCADE
);

CREATE INDEX ix_goal_source_retrievals_goal_checked
    ON goal_source_retrievals (goal_id, checked_at);
