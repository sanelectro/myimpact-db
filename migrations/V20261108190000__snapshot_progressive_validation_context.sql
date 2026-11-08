ALTER TABLE goal_validation_runs
    ADD COLUMN input_context JSONB,
    ADD COLUMN result_context JSONB;
