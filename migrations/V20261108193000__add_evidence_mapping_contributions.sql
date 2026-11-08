ALTER TABLE evidence_mappings
    ADD COLUMN mapping_kind VARCHAR(16) NOT NULL DEFAULT 'PRIMARY',
    ADD COLUMN contribution_description TEXT,
    ADD COLUMN created_by_user_id VARCHAR(64),
    ADD CONSTRAINT ck_evidence_mappings_kind
        CHECK (mapping_kind IN ('PRIMARY', 'CONTRIBUTION')),
    ADD CONSTRAINT fk_evidence_mappings_created_by
        FOREIGN KEY (created_by_user_id) REFERENCES users (id) ON DELETE SET NULL;
