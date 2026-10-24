CREATE TABLE source_connections (
    id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    provider VARCHAR(32) NOT NULL,
    external_account_id VARCHAR(200) NOT NULL,
    external_username VARCHAR(300) NOT NULL,
    external_base_url VARCHAR(500),
    access_token_ciphertext TEXT NOT NULL,
    refresh_token_ciphertext TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_source_connections PRIMARY KEY (id),
    CONSTRAINT uq_source_connections_user_provider UNIQUE (user_id, provider),
    CONSTRAINT fk_source_connections_user_id_users
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX ix_source_connections_user_id ON source_connections (user_id);
