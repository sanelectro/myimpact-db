ALTER TABLE goal_versions
    DROP CONSTRAINT ck_goal_version_definition_kind,
    ADD CONSTRAINT ck_goal_version_definition_kind
        CHECK (definition_kind IN ('STANDARD', 'PROPOSAL', 'OBSERVED'));

ALTER TABLE goal_baseline_observations
    ADD COLUMN source_standard_version_id VARCHAR(64),
    ADD CONSTRAINT fk_goal_baseline_observation_source
        FOREIGN KEY (source_standard_version_id, goal_id)
        REFERENCES goal_versions (id, goal_id);

CREATE FUNCTION check_goal_baseline_observation_versions() RETURNS trigger AS $$
DECLARE
    baseline_kind VARCHAR(20);
    source_kind VARCHAR(20);
BEGIN
    SELECT definition_kind INTO baseline_kind
    FROM goal_versions
    WHERE id = NEW.goal_version_id AND goal_id = NEW.goal_id;

    IF NEW.source_standard_version_id IS NOT NULL THEN
        SELECT definition_kind INTO source_kind
        FROM goal_versions
        WHERE id = NEW.source_standard_version_id AND goal_id = NEW.goal_id;
    END IF;

    IF baseline_kind = 'STANDARD'
       AND (NEW.source_standard_version_id IS NULL
            OR NEW.source_standard_version_id = NEW.goal_version_id) THEN
        RETURN NEW;
    END IF;

    IF baseline_kind = 'OBSERVED' AND source_kind = 'STANDARD' THEN
        RETURN NEW;
    END IF;

    RAISE EXCEPTION 'Baseline observation must reference a same-goal standard or observed version and standard source';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_goal_baseline_observation_versions
    BEFORE INSERT ON goal_baseline_observations
    FOR EACH ROW EXECUTE FUNCTION check_goal_baseline_observation_versions();
