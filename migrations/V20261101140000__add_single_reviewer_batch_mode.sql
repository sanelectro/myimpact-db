ALTER TABLE review_batches
    ADD COLUMN review_mode VARCHAR(32) NOT NULL DEFAULT 'DUAL_ADJUDICATED';

ALTER TABLE review_batches
    ADD CONSTRAINT ck_review_batch_mode
    CHECK (review_mode IN ('SINGLE_REVIEWER', 'DUAL_ADJUDICATED'));

ALTER TABLE review_cases
    DROP CONSTRAINT ck_review_case_status;

ALTER TABLE review_cases
    ADD CONSTRAINT ck_review_case_status CHECK (
        status IN ('PENDING_REVIEW', 'REVIEWED', 'AGREED', 'DISAGREEMENT', 'ADJUDICATED')
    );
