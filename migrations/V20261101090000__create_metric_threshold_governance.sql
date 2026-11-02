CREATE TABLE metric_definitions (
    id VARCHAR(128) NOT NULL,
    metric_id VARCHAR(128) NOT NULL,
    definition_version VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,
    definition_json JSON NOT NULL,
    calculation_version VARCHAR(100) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_metric_definitions PRIMARY KEY (id),
    CONSTRAINT uq_metric_definition_version UNIQUE (metric_id, definition_version)
);

CREATE INDEX ix_metric_definitions_metric_active
    ON metric_definitions (metric_id, active);

CREATE TABLE threshold_sets (
    id VARCHAR(64) NOT NULL,
    version INTEGER NOT NULL,
    name VARCHAR(200) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    prompt_version VARCHAR(200) NOT NULL,
    model_identifier VARCHAR(200) NOT NULL,
    model_configuration JSON NOT NULL,
    evaluation_code_version VARCHAR(200) NOT NULL,
    created_by_user_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    proposal_rationale TEXT NOT NULL,
    CONSTRAINT pk_threshold_sets PRIMARY KEY (id),
    CONSTRAINT uq_threshold_set_version
        UNIQUE (dataset_id, dataset_version, version),
    CONSTRAINT ck_threshold_set_version_positive CHECK (version > 0),
    CONSTRAINT ck_threshold_set_status CHECK (
        status IN ('DRAFT', 'PROPOSED', 'APPROVED', 'REJECTED', 'SUPERSEDED', 'REVOKED')
    ),
    CONSTRAINT ck_threshold_set_rationale CHECK (length(trim(proposal_rationale)) > 0),
    CONSTRAINT fk_threshold_set_creator
        FOREIGN KEY (created_by_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE threshold_items (
    id VARCHAR(64) NOT NULL,
    threshold_set_id VARCHAR(64) NOT NULL,
    metric_id VARCHAR(128) NOT NULL,
    metric_definition_version VARCHAR(100) NOT NULL,
    operator VARCHAR(3) NOT NULL,
    threshold_value NUMERIC(8, 6) NOT NULL,
    unit VARCHAR(32) NOT NULL,
    rationale TEXT NOT NULL,
    required BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_threshold_items PRIMARY KEY (id),
    CONSTRAINT uq_threshold_item_metric UNIQUE (threshold_set_id, metric_id),
    CONSTRAINT ck_threshold_item_operator CHECK (operator IN ('>=', '<=')),
    CONSTRAINT ck_threshold_item_ratio_range CHECK (
        threshold_value >= 0 AND threshold_value <= 1
    ),
    CONSTRAINT ck_threshold_item_rationale CHECK (length(trim(rationale)) > 0),
    CONSTRAINT fk_threshold_item_set
        FOREIGN KEY (threshold_set_id) REFERENCES threshold_sets (id) ON DELETE CASCADE
);

CREATE TABLE threshold_approvals (
    id VARCHAR(64) NOT NULL,
    threshold_set_id VARCHAR(64) NOT NULL,
    threshold_set_version INTEGER NOT NULL,
    decision VARCHAR(16) NOT NULL,
    approver_user_id VARCHAR(64) NOT NULL,
    decided_at TIMESTAMPTZ NOT NULL,
    rationale TEXT NOT NULL,
    policy_reference VARCHAR(200),
    CONSTRAINT pk_threshold_approvals PRIMARY KEY (id),
    CONSTRAINT ck_threshold_approval_decision CHECK (
        decision IN ('APPROVED', 'REJECTED')
    ),
    CONSTRAINT ck_threshold_approval_rationale CHECK (length(trim(rationale)) > 0),
    CONSTRAINT fk_threshold_approval_set
        FOREIGN KEY (threshold_set_id) REFERENCES threshold_sets (id) ON DELETE RESTRICT,
    CONSTRAINT fk_threshold_approval_approver
        FOREIGN KEY (approver_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE threshold_audit_events (
    id VARCHAR(64) NOT NULL,
    threshold_set_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    actor_user_id VARCHAR(64) NOT NULL,
    entity_id VARCHAR(128) NOT NULL,
    details JSON NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_threshold_audit_events PRIMARY KEY (id),
    CONSTRAINT fk_threshold_audit_set
        FOREIGN KEY (threshold_set_id) REFERENCES threshold_sets (id) ON DELETE CASCADE,
    CONSTRAINT fk_threshold_audit_actor
        FOREIGN KEY (actor_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE INDEX ix_threshold_audit_set_created
    ON threshold_audit_events (threshold_set_id, created_at, id);
