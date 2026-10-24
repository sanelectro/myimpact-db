ALTER TABLE notifications
    ADD COLUMN metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN evidence_approval_id VARCHAR(64),
    ADD CONSTRAINT fk_notifications_evidence_approval_id
        FOREIGN KEY (evidence_approval_id)
        REFERENCES evidence_approvals (id)
        ON DELETE SET NULL;

CREATE INDEX ix_notifications_evidence_approval_id
    ON notifications (evidence_approval_id);

UPDATE notifications
SET metadata = jsonb_build_object(
    'status', lower(status::text),
    'reason', NULL,
    'notes', NULL
);

CREATE TABLE notification_responses (
    id VARCHAR(64) NOT NULL,
    notification_id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    response_text TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_notification_responses PRIMARY KEY (id),
    CONSTRAINT fk_notification_responses_notification_id
        FOREIGN KEY (notification_id) REFERENCES notifications (id) ON DELETE CASCADE,
    CONSTRAINT fk_notification_responses_user_id
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX ix_notification_responses_notification_id_created_at
    ON notification_responses (notification_id, created_at);

CREATE TABLE notification_history (
    id VARCHAR(64) NOT NULL,
    notification_id VARCHAR(64),
    response_id VARCHAR(64),
    evidence_approval_id VARCHAR(64),
    actor_user_id VARCHAR(64),
    event_type VARCHAR(64) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_notification_history PRIMARY KEY (id),
    CONSTRAINT fk_notification_history_notification_id
        FOREIGN KEY (notification_id) REFERENCES notifications (id) ON DELETE SET NULL,
    CONSTRAINT fk_notification_history_response_id
        FOREIGN KEY (response_id) REFERENCES notification_responses (id) ON DELETE SET NULL,
    CONSTRAINT fk_notification_history_evidence_approval_id
        FOREIGN KEY (evidence_approval_id) REFERENCES evidence_approvals (id) ON DELETE CASCADE,
    CONSTRAINT fk_notification_history_actor_user_id
        FOREIGN KEY (actor_user_id) REFERENCES users (id) ON DELETE SET NULL
);

CREATE INDEX ix_notification_history_notification_id_created_at
    ON notification_history (notification_id, created_at);

CREATE INDEX ix_notification_history_evidence_approval_id_created_at
    ON notification_history (evidence_approval_id, created_at);

INSERT INTO notification_history (
    id,
    notification_id,
    actor_user_id,
    event_type,
    metadata,
    created_at
)
SELECT
    'history-' || md5(notification.id || '-sent'),
    notification.id,
    NULL,
    'notification_sent',
    notification.metadata,
    notification.created_at
FROM notifications AS notification;

INSERT INTO notification_history (
    id,
    notification_id,
    actor_user_id,
    event_type,
    metadata,
    created_at
)
SELECT
    'history-' || md5(notification.id || '-read'),
    notification.id,
    notification.user_id,
    'notification_read',
    jsonb_build_object(
        'status', 'read',
        'reason', 'recipient_marked_read',
        'notes', NULL
    ),
    notification.read_at
FROM notifications AS notification
WHERE notification.read_at IS NOT NULL;
