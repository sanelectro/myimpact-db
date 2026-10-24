CREATE TYPE evidence_approval_status AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'NEEDS_INFORMATION'
);

CREATE TABLE evidence_approvals (
    id VARCHAR(64) NOT NULL,
    mapping_id VARCHAR(64) NOT NULL,
    status evidence_approval_status NOT NULL DEFAULT 'PENDING',
    reviewed_by_user_id VARCHAR(64),
    manager_comment TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    reviewed_at TIMESTAMPTZ,
    CONSTRAINT pk_evidence_approvals PRIMARY KEY (id),
    CONSTRAINT uq_evidence_approvals_mapping_id UNIQUE (mapping_id),
    CONSTRAINT fk_evidence_approvals_mapping_id
        FOREIGN KEY (mapping_id) REFERENCES evidence_mappings (id) ON DELETE CASCADE,
    CONSTRAINT fk_evidence_approvals_reviewed_by_user_id
        FOREIGN KEY (reviewed_by_user_id) REFERENCES users (id) ON DELETE SET NULL
);

CREATE INDEX ix_evidence_approvals_status ON evidence_approvals (status);

INSERT INTO evidence_approvals (id, mapping_id, status, created_at)
SELECT 'approval-' || md5(mapping.id), mapping.id, 'PENDING', mapping.created_at
FROM evidence_mappings AS mapping;

CREATE TYPE notification_status AS ENUM ('UNREAD', 'READ');

CREATE TABLE notifications (
    id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    related_path VARCHAR(500),
    status notification_status NOT NULL DEFAULT 'UNREAD',
    created_at TIMESTAMPTZ NOT NULL,
    read_at TIMESTAMPTZ,
    CONSTRAINT pk_notifications PRIMARY KEY (id),
    CONSTRAINT fk_notifications_user_id
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX ix_notifications_user_status_created_at
    ON notifications (user_id, status, created_at DESC);
