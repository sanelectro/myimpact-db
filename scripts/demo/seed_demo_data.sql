-- Demo seed data for local/demo environments only.
-- Safe to run repeatedly.

INSERT INTO users (
    id,
    name,
    email,
    role,
    created_at,
    updated_at
)
VALUES (
    'demo-user',
    'Demo User',
    'demo-user@abc.com',
    'Lead Engineer',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = NOW();
