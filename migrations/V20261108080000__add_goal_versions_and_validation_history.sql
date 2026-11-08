ALTER TABLE goals
    ADD COLUMN structured_fields JSONB NOT NULL DEFAULT '{}'::JSONB;

CREATE TABLE goal_versions (
    id VARCHAR(64) NOT NULL,
    goal_id VARCHAR(64) NOT NULL,
    version INTEGER NOT NULL,
    origin VARCHAR(20) NOT NULL,
    content JSONB NOT NULL,
    created_by_user_id VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goal_versions PRIMARY KEY (id),
    CONSTRAINT uq_goal_version_number UNIQUE (goal_id, version),
    CONSTRAINT uq_goal_version_id_goal UNIQUE (id, goal_id),
    CONSTRAINT ck_goal_version_positive CHECK (version > 0),
    CONSTRAINT ck_goal_version_origin CHECK (origin IN ('LEGACY', 'USER')),
    CONSTRAINT fk_goal_versions_goal_id_goals
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
);

CREATE INDEX ix_goal_versions_goal_version
    ON goal_versions (goal_id, version);

INSERT INTO goal_versions (
    id,
    goal_id,
    version,
    origin,
    content,
    created_by_user_id,
    created_at
)
SELECT
    md5('goal-version:legacy:' || goal.id),
    goal.id,
    1,
    'LEGACY',
    jsonb_build_object(
        'title', goal.title,
        'description', goal.description,
        'scope', goal.scope,
        'start_date', goal.start_date,
        'end_date', goal.end_date,
        'source', goal.source,
        'source_document_id', goal.source_document_id,
        'structured_fields', goal.structured_fields,
        'criterion_versions', COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'criterion_id', criterion.id,
                        'version_id', criterion_version.id,
                        'version', criterion_version.version,
                        'approval_status', criterion_version.approval_status,
                        'definition', criterion_version.definition
                    )
                    ORDER BY criterion.created_at, criterion.id
                )
                FROM goal_criteria AS criterion
                JOIN LATERAL (
                    SELECT
                        version.id,
                        version.version,
                        version.approval_status,
                        version.definition
                    FROM goal_criterion_versions AS version
                    WHERE version.criterion_id = criterion.id
                    ORDER BY version.version DESC
                    LIMIT 1
                ) AS criterion_version ON TRUE
                WHERE criterion.goal_id = goal.id
                  AND NOT criterion.is_retired
            ),
            '[]'::JSONB
        )
    ),
    NULL,
    goal.updated_at
FROM goals AS goal;

CREATE TABLE goal_validation_runs (
    id VARCHAR(64) NOT NULL,
    goal_id VARCHAR(64) NOT NULL,
    goal_version_id VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL,
    findings JSONB NOT NULL,
    rule_set_version VARCHAR(100) NOT NULL,
    prompt_version VARCHAR(100) NOT NULL,
    model_provider VARCHAR(100),
    model_version VARCHAR(200),
    actor_user_id VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goal_validation_runs PRIMARY KEY (id),
    CONSTRAINT ck_goal_validation_run_status
        CHECK (status IN ('READY', 'NEEDS_IMPROVEMENT', 'NEEDS_REVIEW', 'INVALID')),
    CONSTRAINT fk_goal_validation_runs_goal_id_goals
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_validation_runs_version_goal
        FOREIGN KEY (goal_version_id, goal_id)
        REFERENCES goal_versions (id, goal_id) ON DELETE CASCADE
);

CREATE INDEX ix_goal_validation_runs_goal_created
    ON goal_validation_runs (goal_id, created_at);
CREATE INDEX ix_goal_validation_runs_version
    ON goal_validation_runs (goal_version_id);

CREATE FUNCTION reject_goal_history_mutation() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR pg_trigger_depth() <= 1 THEN
        RAISE EXCEPTION 'Goal versions and validation runs are immutable';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_goal_versions_immutable
    BEFORE UPDATE OR DELETE ON goal_versions
    FOR EACH ROW EXECUTE FUNCTION reject_goal_history_mutation();

CREATE TRIGGER trg_goal_validation_runs_immutable
    BEFORE UPDATE OR DELETE ON goal_validation_runs
    FOR EACH ROW EXECUTE FUNCTION reject_goal_history_mutation();
