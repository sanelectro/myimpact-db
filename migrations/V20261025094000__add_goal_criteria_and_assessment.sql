CREATE TYPE goal_criterion_type AS ENUM (
    'BINARY',
    'MILESTONE_BASED',
    'MEASURABLE_TARGET'
);

CREATE TYPE goal_criterion_approval_status AS ENUM (
    'PROPOSED',
    'APPROVED'
);

CREATE TYPE goal_criterion_result AS ENUM (
    'NOT_ASSESSED',
    'NOT_STARTED',
    'IN_PROGRESS',
    'MET',
    'NEEDS_REVIEW'
);

CREATE TYPE goal_assessment_lifecycle AS ENUM (
    'CURRENT',
    'STALE',
    'OBSOLETE'
);

CREATE TYPE goal_assessment_run_status AS ENUM (
    'PENDING',
    'RUNNING',
    'COMPLETED',
    'PARTIAL',
    'FAILED'
);

CREATE TYPE goal_assessment_event_lifecycle AS ENUM (
    'CURRENT',
    'STALE',
    'OBSOLETE'
);

CREATE TABLE goal_criteria (
    id VARCHAR(64) NOT NULL,
    goal_id VARCHAR(64) NOT NULL,
    current_version INTEGER,
    is_retired BOOLEAN NOT NULL DEFAULT FALSE,
    created_by_user_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goal_criteria PRIMARY KEY (id),
    CONSTRAINT fk_goal_criteria_goal_id
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_criteria_created_by_user_id
        FOREIGN KEY (created_by_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE INDEX ix_goal_criteria_goal_id ON goal_criteria (goal_id);

CREATE TABLE goal_criterion_versions (
    id VARCHAR(64) NOT NULL,
    criterion_id VARCHAR(64) NOT NULL,
    version INTEGER NOT NULL,
    criterion_type goal_criterion_type NOT NULL,
    definition JSON NOT NULL,
    approval_status goal_criterion_approval_status NOT NULL DEFAULT 'PROPOSED',
    created_by_user_id VARCHAR(64) NOT NULL,
    prompt_version VARCHAR(100),
    model_version VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL,
    approved_by_user_id VARCHAR(64),
    approved_at TIMESTAMPTZ,
    CONSTRAINT pk_goal_criterion_versions PRIMARY KEY (id),
    CONSTRAINT uq_goal_criterion_version UNIQUE (criterion_id, version),
    CONSTRAINT ck_goal_criterion_version_positive CHECK (version > 0),
    CONSTRAINT fk_goal_criterion_versions_criterion_id
        FOREIGN KEY (criterion_id) REFERENCES goal_criteria (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_criterion_versions_created_by_user_id
        FOREIGN KEY (created_by_user_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT fk_goal_criterion_versions_approved_by_user_id
        FOREIGN KEY (approved_by_user_id) REFERENCES users (id) ON DELETE SET NULL
);

CREATE TABLE goal_assessment_runs (
    id VARCHAR(64) NOT NULL,
    batch_id VARCHAR(64),
    goal_id VARCHAR(64) NOT NULL,
    requested_by_user_id VARCHAR(64) NOT NULL,
    status goal_assessment_run_status NOT NULL DEFAULT 'PENDING',
    trigger_type VARCHAR(50) NOT NULL,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    CONSTRAINT pk_goal_assessment_runs PRIMARY KEY (id),
    CONSTRAINT fk_goal_assessment_runs_goal_id
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_assessment_runs_requested_by_user_id
        FOREIGN KEY (requested_by_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE INDEX ix_goal_assessment_runs_goal_created
    ON goal_assessment_runs (goal_id, created_at);
CREATE INDEX ix_goal_assessment_runs_batch_id ON goal_assessment_runs (batch_id);

CREATE TABLE goal_criterion_assessments (
    id VARCHAR(64) NOT NULL,
    run_id VARCHAR(64) NOT NULL,
    criterion_id VARCHAR(64) NOT NULL,
    criterion_version_id VARCHAR(64) NOT NULL,
    result goal_criterion_result NOT NULL,
    lifecycle_state goal_assessment_lifecycle NOT NULL DEFAULT 'CURRENT',
    progress_percentage INTEGER,
    rationale TEXT NOT NULL,
    confidence DOUBLE PRECISION NOT NULL,
    measured_value DOUBLE PRECISION,
    completed_milestone_ids JSON NOT NULL DEFAULT '[]'::json,
    input_fingerprint VARCHAR(64) NOT NULL,
    model_version VARCHAR(200),
    prompt_version VARCHAR(100) NOT NULL,
    invalidation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goal_criterion_assessments PRIMARY KEY (id),
    CONSTRAINT ck_goal_criterion_assessment_progress
        CHECK (progress_percentage IS NULL OR progress_percentage BETWEEN 0 AND 100),
    CONSTRAINT ck_goal_criterion_assessment_confidence
        CHECK (confidence BETWEEN 0 AND 1),
    CONSTRAINT fk_goal_criterion_assessments_run_id
        FOREIGN KEY (run_id) REFERENCES goal_assessment_runs (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_criterion_assessments_criterion_id
        FOREIGN KEY (criterion_id) REFERENCES goal_criteria (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_criterion_assessments_version_id
        FOREIGN KEY (criterion_version_id) REFERENCES goal_criterion_versions (id) ON DELETE RESTRICT
);

CREATE INDEX ix_goal_criterion_assessments_run_id
    ON goal_criterion_assessments (run_id);
CREATE INDEX ix_goal_criterion_assessments_criterion_version_id
    ON goal_criterion_assessments (criterion_version_id);
CREATE INDEX ix_goal_criterion_assessments_criterion_created
    ON goal_criterion_assessments (criterion_id, created_at);
CREATE INDEX ix_goal_criterion_assessments_input_fingerprint
    ON goal_criterion_assessments (input_fingerprint);

CREATE TABLE goal_criterion_assessment_evidence (
    id VARCHAR(64) NOT NULL,
    assessment_id VARCHAR(64) NOT NULL,
    evidence_mapping_id VARCHAR(64) NOT NULL,
    evidence_version_id VARCHAR(64),
    review_state VARCHAR(50),
    source_validity VARCHAR(50) NOT NULL,
    relationship_type VARCHAR(50) NOT NULL,
    source_url_snapshot VARCHAR(2000),
    citation_excerpt TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goal_criterion_assessment_evidence PRIMARY KEY (id),
    CONSTRAINT uq_goal_criterion_assessment_evidence
        UNIQUE (assessment_id, evidence_mapping_id),
    CONSTRAINT fk_goal_criterion_assessment_evidence_assessment_id
        FOREIGN KEY (assessment_id)
        REFERENCES goal_criterion_assessments (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_criterion_assessment_evidence_mapping_id
        FOREIGN KEY (evidence_mapping_id)
        REFERENCES evidence_mappings (id) ON DELETE RESTRICT,
    CONSTRAINT fk_goal_criterion_assessment_evidence_version_id
        FOREIGN KEY (evidence_version_id)
        REFERENCES evidence_versions (id) ON DELETE SET NULL
);

CREATE INDEX ix_goal_criterion_assessment_evidence_assessment_id
    ON goal_criterion_assessment_evidence (assessment_id);

CREATE TABLE goal_criterion_assessment_events (
    id VARCHAR(64) NOT NULL,
    assessment_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    lifecycle_state goal_assessment_event_lifecycle,
    actor_user_id VARCHAR(64),
    details JSON NOT NULL DEFAULT '{}'::json,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goal_criterion_assessment_events PRIMARY KEY (id),
    CONSTRAINT fk_goal_criterion_assessment_events_assessment_id
        FOREIGN KEY (assessment_id)
        REFERENCES goal_criterion_assessments (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_criterion_assessment_events_actor_user_id
        FOREIGN KEY (actor_user_id) REFERENCES users (id) ON DELETE SET NULL
);

CREATE INDEX ix_goal_criterion_assessment_events_assessment_created
    ON goal_criterion_assessment_events (assessment_id, created_at);
