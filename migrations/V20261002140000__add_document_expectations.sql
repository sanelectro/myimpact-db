-- V20261002140000__add_document_expectations.sql

-- Flyway manages the migration transaction.

CREATE TYPE expectation_category AS ENUM (
    'DELIVERY',
    'TECHNICAL_LEADERSHIP',
    'ARCHITECTURE',
    'MENTORING',
    'INNOVATION',
    'COLLABORATION',
    'OPERATIONAL_EXCELLENCE',
    'BUSINESS_DOMAIN_IMPACT'
);

CREATE TABLE document_expectations (
    id VARCHAR(64) NOT NULL,
    document_id VARCHAR(64) NOT NULL,
    category expectation_category NOT NULL,
    description TEXT NOT NULL,
    evidence_hints JSON NOT NULL,
    source_page INTEGER,
    source_section VARCHAR(500),
    source_text_span TEXT,
    confidence DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_document_expectations PRIMARY KEY (id),
    CONSTRAINT fk_document_expectations_document_id_documents
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE,
    CONSTRAINT ck_document_expectations_confidence
        CHECK (confidence BETWEEN 0 AND 1)
);

CREATE INDEX ix_document_expectations_document_id
    ON document_expectations (document_id);

CREATE INDEX ix_document_expectations_document_category
    ON document_expectations (document_id, category);
