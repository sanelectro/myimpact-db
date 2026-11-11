CREATE TABLE goal_definition_proposal_heads (
    goal_id VARCHAR(64) PRIMARY KEY,
    base_version_id VARCHAR(64) NOT NULL,
    proposal_version_id VARCHAR(64) NOT NULL,
    revision INTEGER NOT NULL,
    relationship_revision INTEGER NOT NULL,
    CONSTRAINT fk_goal_proposal_head_goal
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_proposal_head_base
        FOREIGN KEY (base_version_id, goal_id)
        REFERENCES goal_versions (id, goal_id),
    CONSTRAINT fk_goal_proposal_head_version
        FOREIGN KEY (proposal_version_id, goal_id)
        REFERENCES goal_versions (id, goal_id),
    CONSTRAINT ck_goal_proposal_head_revision CHECK (revision > 0),
    CONSTRAINT ck_goal_proposal_head_relationship_revision CHECK (relationship_revision >= 0)
);

CREATE FUNCTION check_goal_proposal_head_version() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM goal_versions
        WHERE id = NEW.proposal_version_id
          AND goal_id = NEW.goal_id
          AND definition_kind = 'PROPOSAL'
          AND origin = 'USER'
    ) THEN
        RAISE EXCEPTION 'Proposal head must reference a user-managed proposal for the same goal';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_goal_proposal_head_version
    BEFORE INSERT OR UPDATE ON goal_definition_proposal_heads
    FOR EACH ROW EXECUTE FUNCTION check_goal_proposal_head_version();

CREATE TABLE goal_command_receipts (
    actor_user_id VARCHAR(64) NOT NULL,
    command_kind VARCHAR(40) NOT NULL,
    idempotency_key VARCHAR(128) NOT NULL,
    request_hash VARCHAR(64) NOT NULL,
    goal_id VARCHAR(64) NOT NULL,
    result_version_id VARCHAR(64) NOT NULL,
    result_revision INTEGER NOT NULL,
    outcome VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goal_command_receipts
        PRIMARY KEY (actor_user_id, command_kind, idempotency_key),
    CONSTRAINT fk_goal_command_receipt_actor
        FOREIGN KEY (actor_user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_command_receipt_goal
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_command_receipt_result
        FOREIGN KEY (result_version_id, goal_id)
        REFERENCES goal_versions (id, goal_id),
    CONSTRAINT ck_goal_command_receipt_kind CHECK (command_kind = 'PREPARE_DEFINITION'),
    CONSTRAINT ck_goal_command_receipt_key CHECK (length(btrim(idempotency_key)) > 0),
    CONSTRAINT ck_goal_command_receipt_hash
        CHECK (request_hash ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_goal_command_receipt_revision CHECK (result_revision >= 0),
    CONSTRAINT ck_goal_command_receipt_outcome CHECK (outcome IN ('CREATED', 'NO_CHANGE'))
);

CREATE TRIGGER trg_goal_command_receipts_immutable
    BEFORE UPDATE OR DELETE ON goal_command_receipts
    FOR EACH ROW EXECUTE FUNCTION reject_goal_history_mutation();
