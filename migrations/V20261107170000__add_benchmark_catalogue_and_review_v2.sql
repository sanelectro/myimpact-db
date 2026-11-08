CREATE TABLE b_mst_dataset_versions (
    id VARCHAR(64) PRIMARY KEY,
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    content_hash VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL,
    case_count INTEGER NOT NULL CHECK (case_count > 0),
    created_at TIMESTAMPTZ NOT NULL,
    created_by VARCHAR(64) NOT NULL,
    CONSTRAINT uq_b_dataset_version UNIQUE (dataset_id, dataset_version)
);

CREATE INDEX ix_b_dataset_versions_status ON b_mst_dataset_versions (status);

CREATE TABLE b_mst_review_categories (
    id VARCHAR(100) PRIMARY KEY,
    display_name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE b_mst_review_labels (
    id VARCHAR(64) PRIMARY KEY,
    category_id VARCHAR(100) NOT NULL REFERENCES b_mst_review_categories (id) ON DELETE RESTRICT,
    label VARCHAR(64) NOT NULL,
    polarity VARCHAR(32),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_b_review_label UNIQUE (category_id, label)
);

CREATE TABLE b_mst_review_dimensions (
    id VARCHAR(100) PRIMARY KEY,
    display_name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE b_mst_case_versions (
    id VARCHAR(128) PRIMARY KEY,
    dataset_version_id VARCHAR(64) NOT NULL
        REFERENCES b_mst_dataset_versions (id) ON DELETE CASCADE,
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    case_id VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    content_hash VARCHAR(64) NOT NULL,
    case_json JSON NOT NULL,
    label_options JSON NOT NULL,
    dimensions JSON NOT NULL,
    polarity VARCHAR(32),
    label_status VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    created_by VARCHAR(64) NOT NULL,
    CONSTRAINT uq_b_case_version UNIQUE (dataset_id, dataset_version, case_id)
);

CREATE INDEX ix_b_case_versions_category ON b_mst_case_versions (category);

CREATE TABLE b_review_reference_proposals (
    id VARCHAR(64) PRIMARY KEY,
    case_version_id VARCHAR(128) NOT NULL
        REFERENCES b_mst_case_versions (id) ON DELETE RESTRICT,
    source_document VARCHAR(255) NOT NULL,
    source_dataset_id VARCHAR(200) NOT NULL,
    source_dataset_version VARCHAR(200) NOT NULL,
    proposed_label VARCHAR(64) NOT NULL,
    provisional_expected_label VARCHAR(64),
    rationale TEXT NOT NULL CHECK (length(trim(rationale)) > 0),
    confidence VARCHAR(32),
    evidence_mapping_ids JSON NOT NULL,
    review_flags JSON NOT NULL,
    requires_owner_attention BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(32) NOT NULL DEFAULT 'PROPOSED'
        CHECK (status IN ('PROPOSED', 'NEEDS_OWNER_REVIEW', 'APPROVED', 'REJECTED')),
    created_at TIMESTAMPTZ NOT NULL,
    created_by VARCHAR(64) NOT NULL,
    CONSTRAINT uq_b_review_proposal_case_source
        UNIQUE (case_version_id, source_document)
);

CREATE INDEX ix_b_review_proposals_status_attention
    ON b_review_reference_proposals (status, requires_owner_attention);

CREATE TABLE mst_ai_models (
    id VARCHAR(64) PRIMARY KEY,
    model_identifier VARCHAR(200) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    provider VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL
);

INSERT INTO mst_ai_models
    (id, model_identifier, display_name, provider, is_active, created_at)
SELECT 'legacy-' || md5(model_identifier), model_identifier, model_identifier,
       split_part(model_identifier, '/', 1), TRUE, now()
FROM (
    SELECT DISTINCT model_identifier FROM reliability_experiments
    UNION
    SELECT DISTINCT model_identifier FROM reliability_attempts
) model_ids
ON CONFLICT (model_identifier) DO NOTHING;

ALTER TABLE reliability_experiments
    ADD COLUMN ai_model_id VARCHAR(64);
ALTER TABLE reliability_attempts
    ADD COLUMN ai_model_id VARCHAR(64);

UPDATE reliability_experiments e
SET ai_model_id = m.id
FROM mst_ai_models m
WHERE e.model_identifier = m.model_identifier;

UPDATE reliability_attempts a
SET ai_model_id = m.id
FROM mst_ai_models m
WHERE a.model_identifier = m.model_identifier;

ALTER TABLE reliability_experiments
    ADD CONSTRAINT fk_reliability_experiment_ai_model
    FOREIGN KEY (ai_model_id) REFERENCES mst_ai_models (id) ON DELETE RESTRICT;
ALTER TABLE reliability_attempts
    ADD CONSTRAINT fk_reliability_attempt_ai_model
    FOREIGN KEY (ai_model_id) REFERENCES mst_ai_models (id) ON DELETE RESTRICT;

CREATE TABLE b_review_batches (
    id VARCHAR(64) PRIMARY KEY,
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    review_mode VARCHAR(32) NOT NULL DEFAULT 'DUAL_ADJUDICATED'
        CHECK (review_mode IN ('SINGLE_REVIEWER', 'DUAL_ADJUDICATED')),
    status VARCHAR(32) NOT NULL,
    expected_case_count INTEGER NOT NULL CHECK (expected_case_count > 0),
    started_by_user_id VARCHAR(64) NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    created_by VARCHAR(64) NOT NULL,
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(64),
    CONSTRAINT uq_b_review_batch_dataset_version UNIQUE (dataset_id, dataset_version),
    CONSTRAINT ck_b_review_batch_status CHECK (
        status IN ('DRAFT_UNREVIEWED', 'IN_REVIEW', 'REVIEW_BLOCKED', 'HUMAN_REVIEWED')
    )
);

CREATE INDEX ix_b_review_batches_dataset_status ON b_review_batches (dataset_id, status);

CREATE TABLE b_review_cases (
    id VARCHAR(128) PRIMARY KEY,
    batch_id VARCHAR(64) NOT NULL REFERENCES b_review_batches (id) ON DELETE CASCADE,
    case_id VARCHAR(200) NOT NULL,
    case_version_id VARCHAR(128) REFERENCES b_mst_case_versions (id) ON DELETE RESTRICT,
    category VARCHAR(100),
    status VARCHAR(32) NOT NULL,
    CONSTRAINT uq_b_review_case UNIQUE (batch_id, case_id),
    CONSTRAINT ck_b_review_case_status CHECK (
        status IN ('PENDING_REVIEW', 'REVIEWED', 'AGREED', 'DISAGREEMENT', 'ADJUDICATED')
    )
);

CREATE INDEX ix_b_review_cases_batch_status ON b_review_cases (batch_id, status);

CREATE TABLE b_review_assignments (
    id VARCHAR(64) PRIMARY KEY,
    case_record_id VARCHAR(128) NOT NULL REFERENCES b_review_cases (id) ON DELETE CASCADE,
    reviewer_user_id VARCHAR(64) NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    slot INTEGER NOT NULL CHECK (slot IN (1, 2)),
    assigned_by_user_id VARCHAR(64) NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    assigned_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uq_b_review_assignment_reviewer UNIQUE (case_record_id, reviewer_user_id),
    CONSTRAINT uq_b_review_assignment_slot UNIQUE (case_record_id, slot)
);

CREATE TABLE b_reviews (
    id VARCHAR(64) PRIMARY KEY,
    case_record_id VARCHAR(128) NOT NULL REFERENCES b_review_cases (id) ON DELETE RESTRICT,
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    case_id VARCHAR(200) NOT NULL,
    case_version_id VARCHAR(128) REFERENCES b_mst_case_versions (id) ON DELETE RESTRICT,
    reviewer_user_id VARCHAR(64) NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    review_stage VARCHAR(16) NOT NULL DEFAULT 'BLIND'
        CHECK (review_stage IN ('BLIND', 'POST_AI')),
    ai_attempt_id VARCHAR(64) REFERENCES reliability_attempts (id) ON DELETE RESTRICT,
    label VARCHAR(64) NOT NULL,
    rationale TEXT NOT NULL CHECK (length(trim(rationale)) > 0),
    confidence DOUBLE PRECISION CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
    context_notes TEXT,
    evidence_findings JSON,
    submitted_at TIMESTAMPTZ NOT NULL,
    supersedes_review_id VARCHAR(64) REFERENCES b_reviews (id) ON DELETE RESTRICT,
    CONSTRAINT ck_b_post_ai_attempt_required CHECK (
        review_stage <> 'POST_AI' OR ai_attempt_id IS NOT NULL
    ),
    CONSTRAINT uq_b_review_case_reviewer_stage UNIQUE
        (case_record_id, reviewer_user_id, review_stage)
);

CREATE INDEX ix_b_reviews_case_stage_submitted
    ON b_reviews (case_record_id, review_stage, submitted_at);

CREATE TABLE b_adjudications (
    id VARCHAR(64) PRIMARY KEY,
    case_record_id VARCHAR(128) NOT NULL REFERENCES b_review_cases (id) ON DELETE RESTRICT,
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    case_id VARCHAR(200) NOT NULL,
    review_1_id VARCHAR(64) NOT NULL REFERENCES b_reviews (id) ON DELETE RESTRICT,
    review_2_id VARCHAR(64) NOT NULL REFERENCES b_reviews (id) ON DELETE RESTRICT,
    adjudicator_user_id VARCHAR(64) NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    final_label VARCHAR(64) NOT NULL,
    rationale TEXT NOT NULL CHECK (length(trim(rationale)) > 0),
    adjudicated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uq_b_adjudication_case UNIQUE (case_record_id),
    CONSTRAINT ck_b_adjudication_distinct_reviews CHECK (review_1_id <> review_2_id)
);

CREATE TABLE b_review_audit_events (
    id VARCHAR(64) PRIMARY KEY,
    batch_id VARCHAR(64) NOT NULL REFERENCES b_review_batches (id) ON DELETE CASCADE,
    case_record_id VARCHAR(128) REFERENCES b_review_cases (id) ON DELETE CASCADE,
    event_type VARCHAR(64) NOT NULL,
    actor_user_id VARCHAR(64) NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    entity_id VARCHAR(128) NOT NULL,
    details_json JSON NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX ix_b_review_audit_batch_created
    ON b_review_audit_events (batch_id, created_at, id);

CREATE TABLE b_human_ai_comparisons (
    id VARCHAR(64) PRIMARY KEY,
    case_record_id VARCHAR(128) NOT NULL REFERENCES b_review_cases (id) ON DELETE CASCADE,
    case_version_id VARCHAR(128) NOT NULL REFERENCES b_mst_case_versions (id) ON DELETE RESTRICT,
    blind_review_id VARCHAR(64) NOT NULL REFERENCES b_reviews (id) ON DELETE RESTRICT,
    post_ai_review_id VARCHAR(64) REFERENCES b_reviews (id) ON DELETE RESTRICT,
    ai_attempt_id VARCHAR(64) NOT NULL REFERENCES reliability_attempts (id) ON DELETE RESTRICT,
    agreement BOOLEAN NOT NULL,
    comparison_json JSON NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uq_b_human_ai_blind_attempt UNIQUE (blind_review_id, ai_attempt_id),
    CONSTRAINT ck_b_human_ai_distinct_reviews CHECK (
        post_ai_review_id IS NULL OR post_ai_review_id <> blind_review_id
    )
);

CREATE INDEX ix_b_human_ai_case_created
    ON b_human_ai_comparisons (case_record_id, created_at);

INSERT INTO b_mst_dataset_versions
    (id, dataset_id, dataset_version, content_hash, status, case_count, created_at, created_by)
SELECT 'legacy-' || md5(b.dataset_id || ':' || b.dataset_version),
       b.dataset_id, b.dataset_version, 'legacy', 'LEGACY',
       GREATEST(count(c.id)::integer, 1), b.started_at, b.started_by_user_id
FROM review_batches b
LEFT JOIN review_cases c ON c.batch_id = b.id
GROUP BY b.id, b.dataset_id, b.dataset_version, b.started_at, b.started_by_user_id
ON CONFLICT (dataset_id, dataset_version) DO NOTHING;

INSERT INTO b_mst_case_versions
    (id, dataset_version_id, dataset_id, dataset_version, case_id, category,
     content_hash, case_json, label_options, dimensions, polarity, label_status,
     created_at, created_by)
SELECT 'legacy-' || md5(b.dataset_id || ':' || b.dataset_version || ':' || c.case_id),
       'legacy-' || md5(b.dataset_id || ':' || b.dataset_version),
       b.dataset_id, b.dataset_version, c.case_id, 'legacy', 'legacy',
       '{}'::json, '[]'::json, '[]'::json, NULL, 'LEGACY',
       b.started_at, b.started_by_user_id
FROM review_cases c
JOIN review_batches b ON b.id = c.batch_id
ON CONFLICT (dataset_id, dataset_version, case_id) DO NOTHING;

INSERT INTO b_review_batches
    (id, dataset_id, dataset_version, review_mode, status, expected_case_count,
     started_by_user_id, started_at, completed_at, created_at, created_by)
SELECT id, dataset_id, dataset_version, 'DUAL_ADJUDICATED', status,
       expected_case_count, started_by_user_id, started_at, completed_at,
       started_at, started_by_user_id
FROM review_batches;

INSERT INTO b_review_cases (id, batch_id, case_id, case_version_id, status)
SELECT c.id, c.batch_id, c.case_id,
       'legacy-' || md5(b.dataset_id || ':' || b.dataset_version || ':' || c.case_id),
       c.status
FROM review_cases c
JOIN review_batches b ON b.id = c.batch_id;

INSERT INTO b_review_assignments
    (id, case_record_id, reviewer_user_id, slot, assigned_by_user_id, assigned_at)
SELECT id, case_record_id, reviewer_user_id, slot, assigned_by_user_id, assigned_at
FROM review_assignments;

INSERT INTO b_reviews
    (id, case_record_id, dataset_id, dataset_version, case_id, case_version_id,
     reviewer_user_id, review_stage, label, rationale, submitted_at, supersedes_review_id)
SELECT r.id, r.case_record_id, r.dataset_id, r.dataset_version, r.case_id,
       'legacy-' || md5(r.dataset_id || ':' || r.dataset_version || ':' || r.case_id),
       r.reviewer_user_id, 'BLIND', r.label, r.rationale, r.submitted_at,
       r.supersedes_review_id
FROM reviews r;

INSERT INTO b_adjudications
    (id, case_record_id, dataset_id, dataset_version, case_id, review_1_id,
     review_2_id, adjudicator_user_id, final_label, rationale, adjudicated_at)
SELECT id, case_record_id, dataset_id, dataset_version, case_id, review_1_id,
       review_2_id, adjudicator_user_id, final_label, rationale, adjudicated_at
FROM adjudications;

INSERT INTO b_review_audit_events
    (id, batch_id, case_record_id, event_type, actor_user_id, entity_id, details_json, created_at)
SELECT id, batch_id, case_record_id, event_type, actor_user_id, entity_id,
       details_json, created_at
FROM review_audit_events;
