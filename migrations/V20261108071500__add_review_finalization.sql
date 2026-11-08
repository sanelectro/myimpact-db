ALTER TABLE b_reviews
    ADD COLUMN is_final BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE b_reviews
    ADD COLUMN updated_at TIMESTAMPTZ;

UPDATE b_reviews
SET updated_at = submitted_at;

UPDATE b_reviews AS review
SET is_final = TRUE
WHERE EXISTS (
    SELECT 1
    FROM b_adjudications AS adjudication
    WHERE adjudication.case_record_id = review.case_record_id
);

UPDATE b_review_cases AS review_case
SET status = 'PENDING_REVIEW'
WHERE NOT EXISTS (
    SELECT 1
    FROM b_reviews AS review
    WHERE review.case_record_id = review_case.id
      AND review.is_final
      AND review.review_stage IN ('BLIND', 'PROPOSAL_ASSISTED')
)
  AND review_case.status <> 'ADJUDICATED';

UPDATE b_review_batches AS batch
SET status = 'IN_REVIEW',
    completed_at = NULL
WHERE batch.expected_case_count = (
        SELECT COUNT(*)
        FROM b_review_cases AS review_case
        WHERE review_case.batch_id = batch.id
    )
  AND EXISTS (
        SELECT 1
        FROM b_review_cases AS review_case
        WHERE review_case.batch_id = batch.id
          AND review_case.status = 'PENDING_REVIEW'
    )
  AND batch.status = 'HUMAN_REVIEWED';
