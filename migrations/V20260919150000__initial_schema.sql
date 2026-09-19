-- V20260919150000__initial_schema.sql
-- Initial MyImpact database schema.
--
-- This migration is intentionally the first source-controlled schema definition.
-- Do not edit after it has been applied. Create a new versioned migration instead.


CREATE TYPE evidence_source_type AS ENUM (
    'JIRA',
    'GITHUB',
    'CONFLUENCE',
    'WORKDAY',
    'PERSONAL',
    'DOCUMENT',
    'OTHER'
);

CREATE TYPE evidence_status AS ENUM (
    'ACTIVE',
    'ARCHIVED',
    'DELETED'
);

CREATE TYPE evidence_relevance AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH'
);

CREATE TYPE goal_status AS ENUM (
    'DRAFT',
    'ACTIVE',
    'COMPLETED',
    'ARCHIVED'
);

CREATE TYPE impact_type AS ENUM (
    'TECHNICAL',
    'BUSINESS',
    'CUSTOMER',
    'RELIABILITY',
    'PERFORMANCE',
    'AUTOMATION',
    'LEADERSHIP',
    'MENTORING',
    'INNOVATION',
    'OPERATIONAL'
);

CREATE TYPE report_type AS ENUM (
    'MONTHLY_IMPACT',
    'QUARTERLY_IMPACT',
    'ANNUAL_PERFORMANCE',
    'GOAL_PROGRESS',
    'PROMOTION_EVIDENCE',
    'ONE_TO_ONE'
);

CREATE TYPE report_status AS ENUM (
    'CURRENT',
    'STALE',
    'ARCHIVED'
);

CREATE TYPE document_type AS ENUM (
    'GOAL',
    'ROLE',
    'RESPONSIBILITY',
    'ONE_TO_ONE',
    'DEVELOPMENT',
    'PERSONAL_EVIDENCE'
);

CREATE TYPE document_status AS ENUM (
    'UPLOADED',
    'PROCESSED',
    'FAILED'
);

CREATE TYPE document_scope_type AS ENUM (
    'GLOBAL',
    'ROLE',
    'EMPLOYEE'
);

CREATE TABLE users (
    id VARCHAR(64) NOT NULL,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(320) NOT NULL,
    role VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email)
);

CREATE TABLE goals (
    id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    status goal_status NOT NULL,
    source VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_goals PRIMARY KEY (id),
    CONSTRAINT fk_goals_user_id_users
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE evidence (
    id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    source_type evidence_source_type NOT NULL,
    source_id VARCHAR(500),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    source_url VARCHAR(2000),
    captured_at TIMESTAMPTZ NOT NULL,
    source_updated_at TIMESTAMPTZ,
    content_hash VARCHAR(128),
    status evidence_status NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_evidence PRIMARY KEY (id),
    CONSTRAINT fk_evidence_user_id_users
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE evidence_versions (
    id VARCHAR(64) NOT NULL,
    evidence_id VARCHAR(64) NOT NULL,
    version INTEGER NOT NULL,
    content TEXT NOT NULL,
    content_hash VARCHAR(128) NOT NULL,
    source_updated_at TIMESTAMPTZ,
    captured_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_evidence_versions PRIMARY KEY (id),
    CONSTRAINT uq_evidence_version UNIQUE (evidence_id, version),
    CONSTRAINT fk_evidence_versions_evidence_id_evidence
        FOREIGN KEY (evidence_id) REFERENCES evidence (id) ON DELETE CASCADE
);

CREATE TABLE evidence_mappings (
    id VARCHAR(64) NOT NULL,
    evidence_id VARCHAR(64) NOT NULL,
    goal_id VARCHAR(64) NOT NULL,
    relevance evidence_relevance NOT NULL,
    reason TEXT,
    confidence DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_evidence_mappings PRIMARY KEY (id),
    CONSTRAINT uq_evidence_goal_mapping UNIQUE (evidence_id, goal_id),
    CONSTRAINT fk_evidence_mappings_evidence_id_evidence
        FOREIGN KEY (evidence_id) REFERENCES evidence (id) ON DELETE CASCADE,
    CONSTRAINT fk_evidence_mappings_goal_id_goals
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
);

CREATE TABLE impact_assessments (
    id VARCHAR(64) NOT NULL,
    evidence_id VARCHAR(64) NOT NULL,
    goal_id VARCHAR(64) NOT NULL,
    impact_type impact_type NOT NULL,
    impact_summary TEXT NOT NULL,
    impact_score DOUBLE PRECISION NOT NULL,
    confidence DOUBLE PRECISION NOT NULL,
    assessment_version INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_impact_assessments PRIMARY KEY (id),
    CONSTRAINT fk_impact_assessments_evidence_id_evidence
        FOREIGN KEY (evidence_id) REFERENCES evidence (id) ON DELETE CASCADE,
    CONSTRAINT fk_impact_assessments_goal_id_goals
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
);

CREATE TABLE reports (
    id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    report_type report_type NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    content TEXT NOT NULL,
    version INTEGER NOT NULL,
    status report_status NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_reports PRIMARY KEY (id),
    CONSTRAINT fk_reports_user_id_users
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE documents (
    id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    document_type document_type NOT NULL,
    scope_type document_scope_type NOT NULL,
    scope_id VARCHAR(500),
    file_name VARCHAR(500) NOT NULL,
    content_type VARCHAR(200) NOT NULL,
    storage_path VARCHAR(2000) NOT NULL,
    extracted_text TEXT,
    source VARCHAR(500),
    effective_start DATE,
    effective_end DATE,
    content_hash VARCHAR(128),
    status document_status NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_documents PRIMARY KEY (id),
    CONSTRAINT fk_documents_user_id_users
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX ix_users_email ON users (email);
CREATE INDEX ix_goals_user_id ON goals (user_id);
CREATE INDEX ix_evidence_user_id ON evidence (user_id);
CREATE INDEX ix_evidence_source ON evidence (source_type, source_id);
CREATE INDEX ix_evidence_versions_evidence_id ON evidence_versions (evidence_id);
CREATE INDEX ix_evidence_mappings_evidence_id ON evidence_mappings (evidence_id);
CREATE INDEX ix_evidence_mappings_goal_id ON evidence_mappings (goal_id);
CREATE INDEX ix_impact_assessments_evidence_id ON impact_assessments (evidence_id);
CREATE INDEX ix_impact_assessments_goal_id ON impact_assessments (goal_id);
CREATE INDEX ix_reports_user_id ON reports (user_id);
CREATE INDEX ix_documents_user_id ON documents (user_id);
CREATE INDEX ix_documents_content_hash ON documents (content_hash);
CREATE INDEX ix_documents_scope ON documents (scope_type, scope_id);
