ALTER TABLE b_reviews
    DROP CONSTRAINT b_reviews_review_stage_check;

ALTER TABLE b_reviews
    ALTER COLUMN review_stage TYPE VARCHAR(32);

ALTER TABLE b_reviews
    ADD COLUMN reference_proposal_id VARCHAR(64)
        REFERENCES b_review_reference_proposals (id) ON DELETE RESTRICT;

ALTER TABLE b_reviews
    ADD CONSTRAINT ck_b_review_stage
        CHECK (review_stage IN ('BLIND', 'POST_AI', 'PROPOSAL_ASSISTED'));

ALTER TABLE b_reviews
    ADD CONSTRAINT ck_b_review_proposal_reference_required
        CHECK (
            (review_stage = 'PROPOSAL_ASSISTED' AND reference_proposal_id IS NOT NULL)
            OR (review_stage <> 'PROPOSAL_ASSISTED' AND reference_proposal_id IS NULL)
        );

CREATE INDEX ix_b_reviews_reference_proposal
    ON b_reviews (reference_proposal_id)
    WHERE reference_proposal_id IS NOT NULL;
