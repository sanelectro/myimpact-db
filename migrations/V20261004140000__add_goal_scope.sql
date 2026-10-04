-- Add goal scope so goals can be distinguished as personal, team or organization goals.

CREATE TYPE goal_scope AS ENUM (
    'PERSONAL',
    'TEAM',
    'ORGANIZATION'
);

ALTER TABLE goals
    ADD COLUMN scope goal_scope NOT NULL DEFAULT 'PERSONAL';
