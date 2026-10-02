-- V20261002150000__add_document_chunks.sql

-- Flyway manages the migration transaction.

CREATE TABLE document_chunks (
    id VARCHAR(64) NOT NULL,
    document_id VARCHAR(64) NOT NULL,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL,
    heading_path JSON NOT NULL,
    document_type document_type NOT NULL,
    scope_type document_scope_type NOT NULL,
    scope_id VARCHAR(500),
    metadata JSON NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_document_chunks PRIMARY KEY (id),
    CONSTRAINT fk_document_chunks_document_id_documents
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE,
    CONSTRAINT ck_document_chunks_chunk_index
        CHECK (chunk_index >= 0),
    CONSTRAINT uq_document_chunks_document_index
        UNIQUE (document_id, chunk_index)
);

CREATE INDEX ix_document_chunks_document_id
    ON document_chunks (document_id);

CREATE INDEX ix_document_chunks_document_index
    ON document_chunks (document_id, chunk_index);
