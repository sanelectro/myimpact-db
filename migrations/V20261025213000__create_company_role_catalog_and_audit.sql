CREATE TABLE organization_roles (
    id VARCHAR(64) NOT NULL,
    organization_id VARCHAR(64) NOT NULL,
    name VARCHAR(200) NOT NULL,
    normalized_name VARCHAR(200) NOT NULL,
    summary TEXT,
    created_by_user_id VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_organization_roles PRIMARY KEY (id),
    CONSTRAINT uq_organization_roles_name UNIQUE (organization_id, normalized_name),
    CONSTRAINT fk_organization_roles_organization_id
        FOREIGN KEY (organization_id) REFERENCES organizations (id) ON DELETE CASCADE,
    CONSTRAINT fk_organization_roles_created_by_user_id
        FOREIGN KEY (created_by_user_id) REFERENCES users (id) ON DELETE SET NULL
);

CREATE INDEX ix_organization_roles_organization_id
    ON organization_roles (organization_id);

CREATE TABLE organization_role_responsibilities (
    id VARCHAR(64) NOT NULL,
    role_id VARCHAR(64) NOT NULL,
    statement VARCHAR(2000) NOT NULL,
    position INTEGER NOT NULL,
    CONSTRAINT pk_organization_role_responsibilities PRIMARY KEY (id),
    CONSTRAINT uq_organization_role_responsibility_position UNIQUE (role_id, position),
    CONSTRAINT fk_organization_role_responsibilities_role_id
        FOREIGN KEY (role_id) REFERENCES organization_roles (id) ON DELETE CASCADE
);

CREATE TABLE organization_role_goals (
    id VARCHAR(64) NOT NULL,
    role_id VARCHAR(64) NOT NULL,
    title VARCHAR(300) NOT NULL,
    description VARCHAR(2000),
    position INTEGER NOT NULL,
    CONSTRAINT pk_organization_role_goals PRIMARY KEY (id),
    CONSTRAINT uq_organization_role_goal_position UNIQUE (role_id, position),
    CONSTRAINT fk_organization_role_goals_role_id
        FOREIGN KEY (role_id) REFERENCES organization_roles (id) ON DELETE CASCADE
);

CREATE TABLE organization_role_competencies (
    id VARCHAR(64) NOT NULL,
    role_id VARCHAR(64) NOT NULL,
    name VARCHAR(200) NOT NULL,
    expected_level VARCHAR(100),
    description VARCHAR(2000),
    position INTEGER NOT NULL,
    CONSTRAINT pk_organization_role_competencies PRIMARY KEY (id),
    CONSTRAINT uq_organization_role_competency_position UNIQUE (role_id, position),
    CONSTRAINT fk_organization_role_competencies_role_id
        FOREIGN KEY (role_id) REFERENCES organization_roles (id) ON DELETE CASCADE
);

CREATE TABLE organization_role_audit_events (
    id VARCHAR(64) NOT NULL,
    organization_id VARCHAR(64) NOT NULL,
    role_id VARCHAR(64) NOT NULL,
    role_name VARCHAR(200) NOT NULL,
    action VARCHAR(20) NOT NULL,
    actor_user_id VARCHAR(64),
    actor_name VARCHAR(200) NOT NULL,
    actor_role VARCHAR(200) NOT NULL,
    before_snapshot JSON,
    after_snapshot JSON,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_organization_role_audit_events PRIMARY KEY (id),
    CONSTRAINT ck_organization_role_audit_action
        CHECK (action IN ('CREATED', 'UPDATED', 'DELETED')),
    CONSTRAINT fk_organization_role_audit_organization_id
        FOREIGN KEY (organization_id) REFERENCES organizations (id) ON DELETE CASCADE,
    CONSTRAINT fk_organization_role_audit_actor_user_id
        FOREIGN KEY (actor_user_id) REFERENCES users (id) ON DELETE SET NULL
);

CREATE INDEX ix_organization_role_audit_company_created
    ON organization_role_audit_events (organization_id, created_at, id);
CREATE INDEX ix_organization_role_audit_role_created
    ON organization_role_audit_events (role_id, created_at, id);
