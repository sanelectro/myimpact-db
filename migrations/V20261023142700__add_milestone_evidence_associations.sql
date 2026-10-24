ALTER TABLE milestones
    ADD CONSTRAINT uq_milestones_id_goal_id UNIQUE (id, goal_id);

ALTER TABLE evidence_mappings
    ADD COLUMN milestone_id VARCHAR(64);

ALTER TABLE evidence_mappings
    ADD CONSTRAINT fk_evidence_mappings_milestone_goal
    FOREIGN KEY (milestone_id, goal_id)
    REFERENCES milestones (id, goal_id);

CREATE INDEX ix_evidence_mappings_milestone_id
    ON evidence_mappings (milestone_id);
