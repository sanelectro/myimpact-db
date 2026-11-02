CREATE TABLE reliability_experiments (
    id VARCHAR(64) NOT NULL,
    name VARCHAR(200) NOT NULL,
    dataset_id VARCHAR(200) NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    case_selection JSON NOT NULL,
    prompt_version VARCHAR(200) NOT NULL,
    model_identifier VARCHAR(200) NOT NULL,
    model_configuration JSON NOT NULL,
    retrieval_configuration_version VARCHAR(200) NOT NULL,
    source_snapshot_id VARCHAR(200),
    evaluation_code_version VARCHAR(200) NOT NULL,
    output_schema_version VARCHAR(100) NOT NULL,
    normalization_version VARCHAR(100) NOT NULL,
    repetitions_per_case INTEGER NOT NULL,
    execution_policy JSON NOT NULL,
    status VARCHAR(32) NOT NULL,
    created_by_user_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    CONSTRAINT pk_reliability_experiments PRIMARY KEY (id),
    CONSTRAINT ck_reliability_experiment_repetitions CHECK (
        repetitions_per_case > 0
    ),
    CONSTRAINT ck_reliability_experiment_status CHECK (
        status IN ('DRAFT', 'VALIDATED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')
    ),
    CONSTRAINT fk_reliability_experiment_creator
        FOREIGN KEY (created_by_user_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE INDEX ix_reliability_experiments_dataset_status
    ON reliability_experiments (dataset_id, dataset_version, status);

CREATE TABLE reliability_attempts (
    id VARCHAR(64) NOT NULL,
    experiment_id VARCHAR(64) NOT NULL,
    case_id VARCHAR(200) NOT NULL,
    sequence INTEGER NOT NULL,
    dataset_version VARCHAR(200) NOT NULL,
    prompt_version VARCHAR(200) NOT NULL,
    model_identifier VARCHAR(200) NOT NULL,
    retrieval_configuration_version VARCHAR(200) NOT NULL,
    source_snapshot_id VARCHAR(200),
    input_fingerprint VARCHAR(128) NOT NULL,
    raw_output JSON,
    normalized_output JSON,
    schema_valid BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(32) NOT NULL,
    error_category VARCHAR(64),
    error_detail TEXT,
    token_usage JSON,
    started_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ,
    CONSTRAINT pk_reliability_attempts PRIMARY KEY (id),
    CONSTRAINT ck_reliability_attempt_sequence CHECK (sequence > 0),
    CONSTRAINT ck_reliability_attempt_status CHECK (
        status IN ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED', 'CANCELLED')
    ),
    CONSTRAINT fk_reliability_attempt_experiment
        FOREIGN KEY (experiment_id)
        REFERENCES reliability_experiments (id) ON DELETE CASCADE,
    CONSTRAINT uq_reliability_attempt_sequence
        UNIQUE (experiment_id, case_id, sequence)
);

CREATE INDEX ix_reliability_attempts_experiment_case
    ON reliability_attempts (experiment_id, case_id, sequence);

CREATE TABLE reliability_comparisons (
    id VARCHAR(64) NOT NULL,
    experiment_id VARCHAR(64) NOT NULL,
    case_id VARCHAR(200) NOT NULL,
    attempt_ids JSON NOT NULL,
    status VARCHAR(32) NOT NULL,
    metrics JSON NOT NULL,
    exact_output_consistent BOOLEAN,
    difference_categories JSON NOT NULL,
    differences JSON NOT NULL,
    exclusion_reasons JSON NOT NULL,
    comparison_version VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_reliability_comparisons PRIMARY KEY (id),
    CONSTRAINT ck_reliability_comparison_status CHECK (
        status IN ('COMPLETE', 'INCOMPLETE')
    ),
    CONSTRAINT fk_reliability_comparison_experiment
        FOREIGN KEY (experiment_id)
        REFERENCES reliability_experiments (id) ON DELETE CASCADE,
    CONSTRAINT uq_reliability_comparison_case
        UNIQUE (experiment_id, case_id)
);

CREATE TABLE reliability_reports (
    id VARCHAR(64) NOT NULL,
    experiment_id VARCHAR(64) NOT NULL,
    report_version VARCHAR(100) NOT NULL,
    metric_definition_versions JSON NOT NULL,
    threshold_set_id VARCHAR(64),
    threshold_set_version INTEGER,
    threshold_result VARCHAR(32) NOT NULL,
    metrics JSON NOT NULL,
    coverage JSON NOT NULL,
    divergent_case_ids JSON NOT NULL,
    limitations JSON NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_reliability_reports PRIMARY KEY (id),
    CONSTRAINT ck_reliability_report_threshold_result CHECK (
        threshold_result IN ('PASS', 'FAIL', 'NOT_EVALUABLE')
    ),
    CONSTRAINT fk_reliability_report_experiment
        FOREIGN KEY (experiment_id)
        REFERENCES reliability_experiments (id) ON DELETE CASCADE
);

CREATE INDEX ix_reliability_reports_experiment_generated
    ON reliability_reports (experiment_id, generated_at);
