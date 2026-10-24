-- Create organization-scoped teams and associate users with their teams.
CREATE TABLE teams (
    id VARCHAR(64) NOT NULL,
    organization_id VARCHAR(64) NOT NULL,
    name VARCHAR(200) NOT NULL,
    normalized_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_teams PRIMARY KEY (id),
    CONSTRAINT fk_teams_organization_id_organizations
        FOREIGN KEY (organization_id) REFERENCES organizations (id),
    CONSTRAINT uq_teams_organization_normalized_name
        UNIQUE (organization_id, normalized_name)
);

ALTER TABLE users
    ADD COLUMN team_id VARCHAR(64),
    ADD CONSTRAINT fk_users_team_id_teams
        FOREIGN KEY (team_id) REFERENCES teams (id);

CREATE INDEX ix_teams_organization_id ON teams (organization_id);
CREATE INDEX ix_users_team_id ON users (team_id);
