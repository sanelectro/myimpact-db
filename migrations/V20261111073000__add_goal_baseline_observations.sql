CREATE TABLE goal_baseline_observations (
    goal_id VARCHAR(64) PRIMARY KEY,
    goal_version_id VARCHAR(64) NOT NULL,
    observed_by_user_id VARCHAR(64) NOT NULL,
    observed_at TIMESTAMPTZ NOT NULL,
    historical_effectivity VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN',
    CONSTRAINT fk_goal_baseline_observation_goal
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_baseline_observation_version
        FOREIGN KEY (goal_version_id, goal_id)
        REFERENCES goal_versions (id, goal_id),
    CONSTRAINT fk_goal_baseline_observation_actor
        FOREIGN KEY (observed_by_user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT ck_goal_baseline_observation_history
        CHECK (historical_effectivity = 'UNKNOWN')
);

CREATE TRIGGER trg_goal_baseline_observations_immutable
    BEFORE UPDATE OR DELETE ON goal_baseline_observations
    FOR EACH ROW EXECUTE FUNCTION reject_goal_history_mutation();
