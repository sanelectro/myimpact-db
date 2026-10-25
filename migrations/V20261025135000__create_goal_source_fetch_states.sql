CREATE TABLE goal_source_fetch_states (
    goal_id VARCHAR(64) NOT NULL,
    provider VARCHAR(20) NOT NULL,
    last_successful_fetch_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goal_source_fetch_states PRIMARY KEY (goal_id, provider),
    CONSTRAINT ck_goal_source_fetch_state_provider
        CHECK (provider IN ('github', 'jira')),
    CONSTRAINT fk_goal_source_fetch_states_goal_id
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
);
