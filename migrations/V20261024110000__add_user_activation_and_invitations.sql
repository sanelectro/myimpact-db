ALTER TABLE users
    ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE auth_user_invitations (
    id VARCHAR(36) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    token_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    CONSTRAINT pk_auth_user_invitations PRIMARY KEY (id),
    CONSTRAINT uq_auth_user_invitations_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_auth_user_invitations_user_id_users
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX ix_auth_user_invitations_user_id
    ON auth_user_invitations (user_id);
CREATE INDEX ix_auth_user_invitations_expires_at
    ON auth_user_invitations (expires_at);
