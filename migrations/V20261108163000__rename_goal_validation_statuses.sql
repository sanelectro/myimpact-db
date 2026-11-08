ALTER TABLE goal_validation_runs
    DROP CONSTRAINT ck_goal_validation_run_status;

ALTER TABLE goal_validation_runs
    ADD CONSTRAINT ck_goal_validation_run_status
    CHECK (status IN (
        'READY', 'NEEDS_IMPROVEMENT', 'NEEDS_REVIEW',
        'NEEDS_REFINEMENT', 'NEEDS_DISCUSSION', 'INVALID'
    ));
