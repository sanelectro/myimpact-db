-- V20260919173517__add_document_extracted_content_path.sql

-- Flyway manages the migration transaction.
-- Add SQL changes here.

ALTER TABLE documents
    ADD COLUMN extracted_content_path VARCHAR(2000);