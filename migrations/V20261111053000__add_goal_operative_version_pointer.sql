ALTER TABLE goals
    ADD COLUMN operative_goal_version_id VARCHAR(64);

ALTER TABLE goals
    ADD CONSTRAINT fk_goals_operative_version_goal
    FOREIGN KEY (operative_goal_version_id, id)
    REFERENCES goal_versions (id, goal_id)
    DEFERRABLE INITIALLY DEFERRED;
