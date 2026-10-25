ALTER TABLE goal_criterion_assessment_evidence
    ADD COLUMN title_snapshot VARCHAR(500),
    ADD COLUMN captured_at_snapshot TIMESTAMPTZ,
    ADD COLUMN source_updated_at_snapshot TIMESTAMPTZ;

UPDATE goal_criterion_assessment_evidence AS assessment_evidence
SET title_snapshot = evidence.title,
    captured_at_snapshot = evidence.captured_at,
    source_updated_at_snapshot = evidence.source_updated_at
FROM evidence_mappings AS mapping
JOIN evidence ON evidence.id = mapping.evidence_id
WHERE mapping.id = assessment_evidence.evidence_mapping_id;

ALTER TABLE goal_criterion_assessment_evidence
    ALTER COLUMN title_snapshot SET NOT NULL,
    ALTER COLUMN captured_at_snapshot SET NOT NULL;
