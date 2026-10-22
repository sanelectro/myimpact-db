CREATE TYPE milestone_status AS ENUM (
    'NOT_STARTED',
    'IN_PROGRESS',
    'COMPLETED',
    'BLOCKED'
);

CREATE TABLE milestones (
    id VARCHAR(64) NOT NULL,
    goal_id VARCHAR(64) NOT NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    completion_criteria TEXT,
    status milestone_status NOT NULL DEFAULT 'NOT_STARTED',
    due_date DATE,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_milestones PRIMARY KEY (id),
    CONSTRAINT fk_milestones_goal_id_goals
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
);

CREATE INDEX ix_milestones_goal_id ON milestones (goal_id);
