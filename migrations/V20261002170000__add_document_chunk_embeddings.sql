-- M3.6.5: Persist document chunk embeddings and enable semantic retrieval.

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE document_chunk_embeddings (
    id VARCHAR(64) NOT NULL,
    chunk_id VARCHAR(64) NOT NULL,
    embedding vector NOT NULL,
    embedding_model VARCHAR(255) NOT NULL,
    embedding_dimensions INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT pk_document_chunk_embeddings PRIMARY KEY (id),
    CONSTRAINT uq_document_chunk_embeddings_chunk_id UNIQUE (chunk_id),
    CONSTRAINT fk_document_chunk_embeddings_chunk_id_document_chunks
        FOREIGN KEY (chunk_id)
        REFERENCES document_chunks (id)
        ON DELETE CASCADE,
    CONSTRAINT ck_document_chunk_embeddings_dimensions_positive
        CHECK (embedding_dimensions > 0)
);

CREATE INDEX ix_document_chunk_embeddings_model_dimensions
    ON document_chunk_embeddings (embedding_model, embedding_dimensions);
