ALTER TABLE goals
    ADD COLUMN goal_level VARCHAR(16),
    ADD COLUMN parent_goal_id VARCHAR(64),
    ADD COLUMN relationship_revision INTEGER NOT NULL DEFAULT 0,
    ADD CONSTRAINT ck_goals_goal_level
        CHECK (goal_level IS NULL OR goal_level IN ('ANNUAL', 'QUARTERLY', 'MONTHLY', 'SPRINT')),
    ADD CONSTRAINT ck_goals_not_own_parent CHECK (parent_goal_id IS DISTINCT FROM id),
    ADD CONSTRAINT ck_goals_relationship_revision CHECK (relationship_revision >= 0),
    ADD CONSTRAINT uq_goals_id_owner UNIQUE (id, user_id);

ALTER TABLE goals
    ADD CONSTRAINT fk_goals_parent_owner
        FOREIGN KEY (parent_goal_id, user_id)
        REFERENCES goals (id, user_id) ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE INDEX ix_goals_parent_goal_id ON goals (parent_goal_id);

CREATE TABLE goal_relationship_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id VARCHAR(64) NOT NULL REFERENCES goals (id) ON DELETE RESTRICT,
    old_parent_goal_id VARCHAR(64),
    new_parent_goal_id VARCHAR(64),
    actor_user_id VARCHAR(64) NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    reason TEXT,
    relationship_revision INTEGER NOT NULL CHECK (relationship_revision > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_goal_relationship_event_revision UNIQUE (goal_id, relationship_revision),
    CONSTRAINT ck_goal_relationship_event_change
        CHECK (old_parent_goal_id IS DISTINCT FROM new_parent_goal_id)
);

CREATE INDEX ix_goal_relationship_events_goal_created
    ON goal_relationship_events (goal_id, relationship_revision);

CREATE FUNCTION enforce_goal_relationship_integrity() RETURNS trigger AS $$
DECLARE
    previous_parent VARCHAR(64);
    actor VARCHAR(64);
BEGIN
    IF TG_OP = 'INSERT' THEN
        previous_parent := NULL;
        IF NEW.relationship_revision <> 0 THEN
            RAISE EXCEPTION 'Initial relationship revision must be zero';
        END IF;
    ELSE
        previous_parent := OLD.parent_goal_id;
        IF NEW.relationship_revision <> OLD.relationship_revision THEN
            RAISE EXCEPTION 'Relationship revision is managed by the database';
        END IF;
    END IF;

    IF NEW.parent_goal_id IS NOT DISTINCT FROM previous_parent THEN
        RETURN NEW;
    END IF;

    IF current_setting('transaction_isolation') <> 'read committed' OR NOT EXISTS (
        SELECT 1 FROM pg_locks
        WHERE locktype = 'advisory' AND pid = pg_backend_pid() AND granted
          AND classid = 1296650324 AND objid = 1 AND objsubid = 2
    ) THEN
        RAISE EXCEPTION 'Acquire the hierarchy transaction lock in a separate READ COMMITTED statement';
    END IF;

    actor := NULLIF(current_setting('myimpact.relationship_actor', TRUE), '');
    IF actor IS NULL OR actor <> NEW.user_id THEN
        RAISE EXCEPTION 'Hierarchy actor must be the goal owner';
    END IF;

    IF NEW.parent_goal_id = NEW.id OR EXISTS (
        WITH RECURSIVE ancestors(id, parent_goal_id) AS (
            SELECT id, parent_goal_id FROM goals WHERE id = NEW.parent_goal_id
            UNION
            SELECT goal.id, goal.parent_goal_id
            FROM goals AS goal JOIN ancestors ON goal.id = ancestors.parent_goal_id
        )
        SELECT 1 FROM ancestors WHERE id = NEW.id
    ) THEN
        RAISE EXCEPTION 'Goal hierarchy cannot contain cycles';
    END IF;

    NEW.relationship_revision := COALESCE(NEW.relationship_revision, 0) + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_goal_relationship_integrity
    BEFORE INSERT OR UPDATE OF parent_goal_id, relationship_revision ON goals
    FOR EACH ROW EXECUTE FUNCTION enforce_goal_relationship_integrity();

CREATE FUNCTION record_goal_relationship_event() RETURNS trigger AS $$
DECLARE
    previous_parent VARCHAR(64);
BEGIN
    IF TG_OP = 'UPDATE' THEN
        previous_parent := OLD.parent_goal_id;
    END IF;
    IF NEW.parent_goal_id IS DISTINCT FROM previous_parent THEN
        INSERT INTO goal_relationship_events
            (goal_id, old_parent_goal_id, new_parent_goal_id, actor_user_id, reason, relationship_revision)
        VALUES
            (NEW.id, previous_parent, NEW.parent_goal_id,
             current_setting('myimpact.relationship_actor'),
             NULLIF(current_setting('myimpact.relationship_reason', TRUE), ''),
             NEW.relationship_revision);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_goal_relationship_event
    AFTER INSERT OR UPDATE OF parent_goal_id ON goals
    FOR EACH ROW EXECUTE FUNCTION record_goal_relationship_event();

CREATE FUNCTION reject_goal_relationship_event_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'Goal relationship events are append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_goal_relationship_events_immutable
    BEFORE UPDATE OR DELETE ON goal_relationship_events
    FOR EACH ROW EXECUTE FUNCTION reject_goal_relationship_event_mutation();
