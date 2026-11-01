CREATE TABLE m66_review_batches (
    id VARCHAR(64) NOT NULL,
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'DRAFT_UNREVIEWED',
    expected_case_count INTEGER NOT NULL,
    started_by_user_id VARCHAR(64) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    CONSTRAINT pk_m66_review_batches PRIMARY KEY (id),
    CONSTRAINT uq_m66_review_batch_dataset_version UNIQUE (dataset_id, dataset_version),
    CONSTRAINT ck_m66_batch_case_count_positive CHECK (expected_case_count > 0),
    CONSTRAINT ck_m66_batch_status CHECK (
        status IN ('DRAFT_UNREVIEWED', 'IN_REVIEW', 'REVIEW_BLOCKED', 'HUMAN_REVIEWED')
    ),
    CONSTRAINT fk_m66_review_batch_started_by
        FOREIGN KEY (started_by_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE INDEX ix_m66_review_batches_dataset_status
    ON m66_review_batches (dataset_id, status);

CREATE TABLE m66_review_cases (
    id VARCHAR(128) NOT NULL,
    batch_id VARCHAR(64) NOT NULL,
    case_id VARCHAR(200) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING_REVIEW',
    CONSTRAINT pk_m66_review_cases PRIMARY KEY (id),
    CONSTRAINT uq_m66_review_case UNIQUE (batch_id, case_id),
    CONSTRAINT ck_m66_review_case_status CHECK (
        status IN ('PENDING_REVIEW', 'AGREED', 'DISAGREEMENT', 'ADJUDICATED')
    ),
    CONSTRAINT fk_m66_review_case_batch
        FOREIGN KEY (batch_id) REFERENCES m66_review_batches (id) ON DELETE CASCADE
);

CREATE INDEX ix_m66_review_cases_batch_status
    ON m66_review_cases (batch_id, status);

CREATE TABLE m66_review_assignments (
    id VARCHAR(64) NOT NULL,
    case_record_id VARCHAR(128) NOT NULL,
    reviewer_user_id VARCHAR(64) NOT NULL,
    slot INTEGER NOT NULL,
    assigned_by_user_id VARCHAR(64) NOT NULL,
    assigned_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_m66_review_assignments PRIMARY KEY (id),
    CONSTRAINT uq_m66_review_assignment_reviewer
        UNIQUE (case_record_id, reviewer_user_id),
    CONSTRAINT uq_m66_review_assignment_slot
        UNIQUE (case_record_id, slot),
    CONSTRAINT ck_m66_review_assignment_slot CHECK (slot IN (1, 2)),
    CONSTRAINT fk_m66_review_assignment_case
        FOREIGN KEY (case_record_id) REFERENCES m66_review_cases (id) ON DELETE CASCADE,
    CONSTRAINT fk_m66_review_assignment_reviewer
        FOREIGN KEY (reviewer_user_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT fk_m66_review_assignment_assigned_by
        FOREIGN KEY (assigned_by_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE m66_reviews (
    id VARCHAR(64) NOT NULL,
    case_record_id VARCHAR(128) NOT NULL,
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    case_id VARCHAR(200) NOT NULL,
    reviewer_user_id VARCHAR(64) NOT NULL,
    label VARCHAR(64) NOT NULL,
    rationale TEXT NOT NULL,
    submitted_at TIMESTAMPTZ NOT NULL,
    supersedes_review_id VARCHAR(64),
    CONSTRAINT pk_m66_reviews PRIMARY KEY (id),
    CONSTRAINT uq_m66_review_case_reviewer UNIQUE (case_record_id, reviewer_user_id),
    CONSTRAINT ck_m66_review_rationale CHECK (length(trim(rationale)) > 0),
    CONSTRAINT fk_m66_review_case
        FOREIGN KEY (case_record_id) REFERENCES m66_review_cases (id) ON DELETE RESTRICT,
    CONSTRAINT fk_m66_review_reviewer
        FOREIGN KEY (reviewer_user_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT fk_m66_review_supersedes
        FOREIGN KEY (supersedes_review_id) REFERENCES m66_reviews (id) ON DELETE RESTRICT
);

CREATE INDEX ix_m66_reviews_case_submitted
    ON m66_reviews (case_record_id, submitted_at);

CREATE TABLE m66_adjudications (
    id VARCHAR(64) NOT NULL,
    case_record_id VARCHAR(128) NOT NULL,
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    case_id VARCHAR(200) NOT NULL,
    review_1_id VARCHAR(64) NOT NULL,
    review_2_id VARCHAR(64) NOT NULL,
    adjudicator_user_id VARCHAR(64) NOT NULL,
    final_label VARCHAR(64) NOT NULL,
    rationale TEXT NOT NULL,
    adjudicated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_m66_adjudications PRIMARY KEY (id),
    CONSTRAINT uq_m66_adjudication_case UNIQUE (case_record_id),
    CONSTRAINT ck_m66_adjudication_distinct_reviews CHECK (review_1_id <> review_2_id),
    CONSTRAINT ck_m66_adjudication_rationale CHECK (length(trim(rationale)) > 0),
    CONSTRAINT fk_m66_adjudication_case
        FOREIGN KEY (case_record_id) REFERENCES m66_review_cases (id) ON DELETE RESTRICT,
    CONSTRAINT fk_m66_adjudication_review_1
        FOREIGN KEY (review_1_id) REFERENCES m66_reviews (id) ON DELETE RESTRICT,
    CONSTRAINT fk_m66_adjudication_review_2
        FOREIGN KEY (review_2_id) REFERENCES m66_reviews (id) ON DELETE RESTRICT,
    CONSTRAINT fk_m66_adjudication_adjudicator
        FOREIGN KEY (adjudicator_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE m66_review_audit_events (
    id VARCHAR(64) NOT NULL,
    batch_id VARCHAR(64) NOT NULL,
    case_record_id VARCHAR(128),
    event_type VARCHAR(64) NOT NULL,
    actor_user_id VARCHAR(64) NOT NULL,
    entity_id VARCHAR(128) NOT NULL,
    details_json JSON NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_m66_review_audit_events PRIMARY KEY (id),
    CONSTRAINT fk_m66_review_audit_batch
        FOREIGN KEY (batch_id) REFERENCES m66_review_batches (id) ON DELETE CASCADE,
    CONSTRAINT fk_m66_review_audit_case
        FOREIGN KEY (case_record_id) REFERENCES m66_review_cases (id) ON DELETE CASCADE,
    CONSTRAINT fk_m66_review_audit_actor
        FOREIGN KEY (actor_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE INDEX ix_m66_review_audit_batch_created
    ON m66_review_audit_events (batch_id, created_at, id);
