CREATE TABLE organizations (
    id VARCHAR(64) NOT NULL,
    name VARCHAR(200) NOT NULL,
    normalized_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_organizations PRIMARY KEY (id),
    CONSTRAINT uq_organizations_normalized_name UNIQUE (normalized_name)
);

ALTER TABLE users
    ADD COLUMN organization_id VARCHAR(64),
    ADD COLUMN reporting_manager_id VARCHAR(64),
    ADD CONSTRAINT fk_users_organization_id_organizations
        FOREIGN KEY (organization_id) REFERENCES organizations (id),
    ADD CONSTRAINT fk_users_reporting_manager_id_users
        FOREIGN KEY (reporting_manager_id) REFERENCES users (id) ON DELETE SET NULL,
    ADD CONSTRAINT ck_users_cannot_report_to_self
        CHECK (reporting_manager_id IS NULL OR reporting_manager_id <> id);

ALTER TABLE goals
    ADD COLUMN organization_id VARCHAR(64),
    ADD CONSTRAINT fk_goals_organization_id_organizations
        FOREIGN KEY (organization_id) REFERENCES organizations (id);

CREATE INDEX ix_users_organization_id ON users (organization_id);
CREATE INDEX ix_users_reporting_manager_id ON users (reporting_manager_id);
CREATE INDEX ix_goals_organization_id ON goals (organization_id);
