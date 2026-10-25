-- Demo seed: create role-specific starter goals for users with a matching role.
-- Run after the database migrations. Goals remain drafts so employees and
-- managers can add targets and agree scope before approving them.
-- Re-running is safe: generated IDs are stable, existing titles are skipped,
-- and conflicting IDs are never overwritten.

BEGIN;

WITH role_goal_templates (role_name, template_key, title, description) AS (
    VALUES
        (
            'Intern Software Engineer',
            'scoped-task',
            'Contribute to a scoped engineering task',
            'Complete an assigned development, bug-fix, or support task with guidance and communicate blockers early.'
        ),
        (
            'Intern Software Engineer',
            'testing-debugging',
            'Practice testing and debugging fundamentals',
            'Add basic tests to assigned work and use team tools and conventions to investigate simple issues.'
        ),
        (
            'Intern Software Engineer',
            'document-learning',
            'Document internship learning',
            'Record how assigned work moves through the team development process and share useful learnings with teammates.'
        ),
        (
            'Associate Software Engineer',
            'scoped-delivery',
            'Deliver scoped engineering tasks reliably',
            'Complete assigned components with appropriate guidance, quality, and timely communication.'
        ),
        (
            'Associate Software Engineer',
            'quality-testing',
            'Strengthen code quality and testing habits',
            'Apply team conventions, write basic tests, and use review feedback to improve submitted work.'
        ),
        (
            'Associate Software Engineer',
            'technical-growth',
            'Grow technical capability and team knowledge',
            'Seek mentorship, build familiarity with the team tools, and document useful learnings.'
        ),
        (
            'Software Engineer',
            'feature-delivery',
            'Deliver maintainable and secure features',
            'Implement agreed product functionality with appropriate tests and review.'
        ),
        (
            'Software Engineer',
            'planning-collaboration',
            'Improve delivery planning and collaboration',
            'Contribute to estimates, communicate progress and risks, and align implementation with user needs.'
        ),
        (
            'Software Engineer',
            'quality-reliability',
            'Strengthen software quality and reliability',
            'Resolve relevant defects and improve testing, documentation, performance, or security in owned components.'
        ),
        (
            'Senior Software Engineer',
            'technical-design',
            'Lead robust technical design',
            'Shape a system or feature design with documented trade-offs and appropriate architectural collaboration.'
        ),
        (
            'Senior Software Engineer',
            'end-to-end-delivery',
            'Own a substantial delivery end to end',
            'Plan and deliver a multi-week technical initiative with appropriate quality and stakeholder communication.'
        ),
        (
            'Senior Software Engineer',
            'mentorship',
            'Grow engineering capability through mentorship',
            'Provide actionable review feedback and support technical development for teammates.'
        ),
        (
            'Lead Software Engineer',
            'technical-direction',
            'Improve team technical direction and quality',
            'Guide a design or engineering-practice improvement with appropriate architectural alignment.'
        ),
        (
            'Lead Software Engineer',
            'team-delivery',
            'Strengthen predictable team delivery',
            'Improve planning, work breakdown, prioritization, or risk management for team commitments.'
        ),
        (
            'Lead Software Engineer',
            'team-development',
            'Develop engineers and align work to outcomes',
            'Mentor teammates and connect technical decisions to stakeholder needs and business goals.'
        ),
        (
            'Principal Software Engineer',
            'technical-strategy',
            'Set cross-project technical direction',
            'Guide an architectural or technology decision across projects and communicate its alignment with long-term goals.'
        ),
        (
            'Principal Software Engineer',
            'cross-team-challenge',
            'Resolve a cross-team technical challenge',
            'Coordinate a sustainable response to a complex issue affecting multiple teams or products.'
        ),
        (
            'Principal Software Engineer',
            'engineering-practices',
            'Scale engineering practices and technical leadership',
            'Strengthen a shared engineering practice and mentor senior engineers or emerging technical leaders.'
        ),
        (
            'Lead UX Designer',
            'user-centered-experience',
            'Improve a user-centered product experience',
            'Validate and refine a complex workflow using user research or usability testing.'
        ),
        (
            'Lead UX Designer',
            'design-system',
            'Strengthen design-system consistency and accessibility',
            'Improve reusable design-system guidance and apply it across relevant product experiences.'
        ),
        (
            'Lead UX Designer',
            'design-leadership',
            'Grow design practice and measurable user value',
            'Mentor designers, lead collaborative reviews, and connect design outcomes to user needs.'
        )
),
seed_candidates AS (
    SELECT
        'role-goal-' || md5(u.id || ':' || t.template_key) AS id,
        u.id AS user_id,
        t.title,
        t.description
    FROM users AS u
    JOIN role_goal_templates AS t
        ON lower(btrim(u.role)) = lower(t.role_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM goals AS existing
        WHERE existing.user_id = u.id
          AND lower(existing.title) = lower(t.title)
          AND existing.status <> 'ARCHIVED'
    )
)
INSERT INTO goals (
    id,
    user_id,
    title,
    description,
    scope,
    start_date,
    end_date,
    status,
    sub_status,
    source,
    created_at,
    updated_at
)
SELECT
    candidate.id,
    candidate.user_id,
    candidate.title,
    candidate.description,
    'PERSONAL'::goal_scope,
    NULL,
    NULL,
    'DRAFT'::goal_status,
    'NEEDS_REVIEW'::goal_sub_status,
    'role-responsibilities-seed-v1',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM seed_candidates AS candidate
ON CONFLICT (id) DO NOTHING;

COMMIT;
