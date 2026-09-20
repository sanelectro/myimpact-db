-- V20260920113254__remove_document_extracted_text.sql

-- Flyway manages the migration transaction.

ALTER TABLE documents
    DROP COLUMN extracted_text;