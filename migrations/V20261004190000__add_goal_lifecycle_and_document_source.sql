-- Goal lifecycle: draft -> approved -> active -> completed -> archived.
-- Goal sub-status is operational state and remains separate from assessment state.

ALTER TYPE goal_status ADD VALUE IF NOT EXISTS 'APPROVED' AFTER 'DRAFT';

CREATE TYPE goal_sub_status AS ENUM (
    'NEEDS_REVIEW',
    'READY_FOR_APPROVAL',
    'NOT_STARTED',
    'ON_TRACK',
    'AT_RISK',
    'OFF_TRACK',
    'COMPLETED',
    'NONE'
);

ALTER TABLE goals
    ADD COLUMN sub_status goal_sub_status;

UPDATE goals
SET sub_status = CASE status
    WHEN 'DRAFT' THEN 'NEEDS_REVIEW'::goal_sub_status
    WHEN 'ACTIVE' THEN 'ON_TRACK'::goal_sub_status
    WHEN 'COMPLETED' THEN 'COMPLETED'::goal_sub_status
    WHEN 'ARCHIVED' THEN 'NONE'::goal_sub_status
END;

ALTER TABLE goals
    ALTER COLUMN sub_status SET NOT NULL,
    ALTER COLUMN sub_status SET DEFAULT 'NEEDS_REVIEW';

ALTER TABLE goals
    ADD COLUMN source_document_id VARCHAR(64),
    ADD CONSTRAINT fk_goals_source_document_id_documents
        FOREIGN KEY (source_document_id)
        REFERENCES documents (id)
        ON DELETE SET NULL;

CREATE INDEX ix_goals_source_document_id
    ON goals (source_document_id);
