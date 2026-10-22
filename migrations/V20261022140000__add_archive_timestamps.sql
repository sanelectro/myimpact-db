ALTER TABLE evidence
    ADD COLUMN archived_at TIMESTAMPTZ;

UPDATE evidence
SET archived_at = updated_at
WHERE status = 'ARCHIVED';

ALTER TABLE milestones
    ADD COLUMN archived_at TIMESTAMPTZ;
