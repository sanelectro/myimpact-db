CREATE TABLE goal_version_approvals (
    id VARCHAR(64) NOT NULL,
    goal_id VARCHAR(64) NOT NULL,
    goal_version_id VARCHAR(64) NOT NULL,
    actor_user_id VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goal_version_approvals PRIMARY KEY (id),
    CONSTRAINT uq_goal_version_approval_version UNIQUE (goal_version_id),
    CONSTRAINT fk_goal_version_approvals_goal_id_goals
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_version_approvals_version_goal
        FOREIGN KEY (goal_version_id, goal_id)
        REFERENCES goal_versions (id, goal_id) ON DELETE CASCADE
);

CREATE INDEX ix_goal_version_approvals_goal_created
    ON goal_version_approvals (goal_id, created_at);

CREATE TRIGGER trg_goal_version_approvals_immutable
    BEFORE UPDATE OR DELETE ON goal_version_approvals
    FOR EACH ROW EXECUTE FUNCTION reject_goal_history_mutation();
