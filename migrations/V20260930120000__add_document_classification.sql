-- V20260930120000__add_document_classification.sql

-- Flyway manages the migration transaction.

ALTER TYPE document_type ADD VALUE IF NOT EXISTS 'UNKNOWN';

ALTER TABLE documents
    ADD COLUMN classification_type document_type,
    ADD COLUMN classification_confidence DOUBLE PRECISION,
    ADD COLUMN classification_reason TEXT,
    ADD COLUMN classification_error TEXT,
    ADD COLUMN classified_at TIMESTAMPTZ,
    ADD CONSTRAINT ck_documents_classification_confidence
        CHECK (
            classification_confidence IS NULL
            OR classification_confidence BETWEEN 0 AND 1
        );