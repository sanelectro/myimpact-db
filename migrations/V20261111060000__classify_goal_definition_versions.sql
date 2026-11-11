ALTER TABLE goal_versions
    ADD COLUMN definition_kind VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    ADD CONSTRAINT ck_goal_version_definition_kind
        CHECK (definition_kind IN ('STANDARD', 'PROPOSAL'));
