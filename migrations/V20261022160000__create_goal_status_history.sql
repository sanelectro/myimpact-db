CREATE TABLE goal_status_history (
    id VARCHAR(64) PRIMARY KEY,
    goal_id VARCHAR(64) NOT NULL REFERENCES goals (id) ON DELETE CASCADE,
    from_status goal_status NOT NULL,
    to_status goal_status NOT NULL,
    reason TEXT,
    changed_by_user_id VARCHAR(64) REFERENCES users (id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX ix_goal_status_history_goal_id_created_at
    ON goal_status_history (goal_id, created_at DESC);
