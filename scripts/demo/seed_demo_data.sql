-- Demo seed data for local/demo environments only.
-- Safe to run repeatedly.
--
-- Dataset:
--   user-1      -> rich dataset used for M6.2 dashboard validation
--   user-2      -> partial dataset used for incomplete-state testing
--   user-empty  -> intentionally empty dataset used for empty-state testing
--
-- The seeded goals are modeled as goals imported from Workday.
-- Evidence is modeled as a mixture of realistic source types with measurable outcomes.

BEGIN;

-- -----------------------------------------------------------------------------
-- Users
-- -----------------------------------------------------------------------------

INSERT INTO users (id, name, email, role, created_at, updated_at)
VALUES
    ('user-1', 'Alex Johnson', 'user-1@myimpact.local', 'Lead Software Engineer', '2026-01-05T09:00:00+05:30', '2026-10-01T09:00:00+05:30'),
    ('user-2', 'Priya Sharma', 'user-2@myimpact.local', 'Software Engineer', '2026-01-05T09:00:00+05:30', '2026-10-01T09:00:00+05:30'),
    ('user-empty', 'Empty State User', 'user-empty@myimpact.local', 'Software Engineer', '2026-01-05T09:00:00+05:30', '2026-10-01T09:00:00+05:30')
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = EXCLUDED.updated_at;

-- -----------------------------------------------------------------------------
-- Goals - user-1
-- -----------------------------------------------------------------------------

INSERT INTO goals (
    id, user_id, title, description, scope, start_date, end_date, status, source, created_at, updated_at
)
VALUES
    (
        'goal-user1-reliability',
        'user-1',
        'Improve Production Reliability',
        'Improve observability, operational readiness and incident response across critical production services.',
        'ORGANIZATION',
        '2026-01-01',
        '2026-12-31',
        'ACTIVE',
        'workday-import-demo',
        '2026-01-05T09:00:00+05:30',
        '2026-09-30T18:00:00+05:30'
    ),
    (
        'goal-user1-leadership',
        'user-1',
        'Strengthen Technical Leadership',
        'Increase technical leadership through mentoring, engineering standards, delivery planning and cross-team collaboration.',
        'TEAM',
        '2026-01-01',
        '2026-12-31',
        'ACTIVE',
        'workday-import-demo',
        '2026-01-05T09:05:00+05:30',
        '2026-09-30T18:00:00+05:30'
    ),
    (
        'goal-user1-architecture',
        'user-1',
        'Build Solution Architecture Capability',
        'Move beyond individual implementation toward service architecture, platform standardisation and solution-level technical decisions.',
        'PERSONAL',
        '2026-01-01',
        '2026-12-31',
        'ACTIVE',
        'workday-import-demo',
        '2026-01-05T09:10:00+05:30',
        '2026-09-30T18:00:00+05:30'
    )
,
    (
        'goal-user1-quality',
        'user-1',
        'Improve Engineering Quality',
        'Improve engineering quality through stronger automated testing, code quality practices and safer delivery patterns.',
        'TEAM',
        '2026-01-01',
        '2026-12-31',
        'ACTIVE',
        'workday-import-demo',
        '2026-01-05T09:12:00+05:30',
        '2026-09-30T18:00:00+05:30'
    ),
    (
        'goal-user1-not-started',
        'user-1',
        'Establish AI-Assisted Engineering Practices',
        'Adopt practical AI-assisted engineering practices that improve development effectiveness, quality and technical decision-making.',
        'PERSONAL',
        '2026-01-01',
        '2026-12-31',
        'ACTIVE',
        'workday-import-demo',
        '2026-01-05T09:15:00+05:30',
        '2026-09-30T18:00:00+05:30'
    )
ON CONFLICT (id) DO UPDATE
SET
    user_id = EXCLUDED.user_id,
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    scope = EXCLUDED.scope,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    status = EXCLUDED.status,
    source = EXCLUDED.source,
    updated_at = EXCLUDED.updated_at;

-- -----------------------------------------------------------------------------
-- Goals - user-2 (partial dataset)
-- -----------------------------------------------------------------------------

INSERT INTO goals (
    id, user_id, title, description, start_date, end_date, status, source, created_at, updated_at
)
VALUES
    (
        'goal-user2-delivery',
        'user-2',
        'Improve Delivery Predictability',
        'Improve sprint planning and delivery predictability through clearer technical breakdown and prioritisation.',
        '2026-01-01',
        '2026-12-31',
        'ACTIVE',
        'workday-import-demo',
        '2026-01-06T09:00:00+05:30',
        '2026-09-20T18:00:00+05:30'
    ),
    (
        'goal-user2-quality',
        'user-2',
        'Improve Engineering Quality',
        'Increase automated test coverage and reduce recurring code quality issues.',
        '2026-01-01',
        '2026-12-31',
        'ACTIVE',
        'workday-import-demo',
        '2026-01-06T09:05:00+05:30',
        '2026-09-20T18:00:00+05:30'
    )
ON CONFLICT (id) DO UPDATE
SET
    user_id = EXCLUDED.user_id,
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    status = EXCLUDED.status,
    source = EXCLUDED.source,
    updated_at = EXCLUDED.updated_at;

-- -----------------------------------------------------------------------------
-- Evidence - user-1
-- -----------------------------------------------------------------------------

INSERT INTO evidence (
    id, user_id, source_type, source_id, title, description, source_url,
    captured_at, source_updated_at, content_hash, status, created_at, updated_at
)
VALUES
    (
        'evidence-user1-monitoring',
        'user-1',
        'GITHUB',
        'monitoring-dashboard-work',
        'Expanded production monitoring coverage from 12 to 28 workloads',
        'Expanded Grafana monitoring across production workloads, adding deployment health, CPU, memory and pod restart visibility. Coverage increased from 12 to 28 workloads, a 133% increase.',
        NULL,
        '2026-09-30T10:00:00+05:30',
        '2026-09-30T10:00:00+05:30',
        'seed-user1-monitoring-v1',
        'ACTIVE',
        '2026-09-30T10:00:00+05:30',
        '2026-09-30T10:00:00+05:30'
    ),
    (
        'evidence-user1-incidents',
        'user-1',
        'JIRA',
        'production-incidents-2026',
        'Resolved 40+ production incidents over four months',
        'Led investigation and resolution of more than 40 production incidents over a four-month period, coordinating diagnosis, remediation and follow-up actions.',
        NULL,
        '2026-09-28T17:30:00+05:30',
        '2026-09-28T17:30:00+05:30',
        'seed-user1-incidents-v1',
        'ACTIVE',
        '2026-09-28T17:30:00+05:30',
        '2026-09-28T17:30:00+05:30'
    ),
    (
        'evidence-user1-investigation',
        'user-1',
        'JIRA',
        'incident-investigation-time',
        'Reduced average incident investigation time from 45 to 25 minutes',
        'Introduced better operational dashboards, alerts and troubleshooting guidance, reducing average investigation time from approximately 45 minutes to 25 minutes, a 44% reduction.',
        NULL,
        '2026-09-25T16:00:00+05:30',
        '2026-09-25T16:00:00+05:30',
        'seed-user1-investigation-v1',
        'ACTIVE',
        '2026-09-25T16:00:00+05:30',
        '2026-09-25T16:00:00+05:30'
    ),
    (
        'evidence-user1-mentoring',
        'user-1',
        'PERSONAL',
        'mentoring-notes-2026',
        'Mentored six engineers across backend and platform initiatives',
        'Provided technical guidance, design reviews and implementation support to a team of six engineers across .NET and Go backend initiatives.',
        NULL,
        '2026-09-22T18:00:00+05:30',
        '2026-09-22T18:00:00+05:30',
        'seed-user1-mentoring-v1',
        'ACTIVE',
        '2026-09-22T18:00:00+05:30',
        '2026-09-22T18:00:00+05:30'
    ),
    (
        'evidence-user1-test-coverage',
        'user-1',
        'GITHUB',
        'test-coverage-improvement',
        'Improved automated test coverage from 62% to 80%',
        'Introduced additional unit and service-level tests and raised automated test coverage from 62% to 80%, an improvement of 18 percentage points.',
        NULL,
        '2026-09-18T14:00:00+05:30',
        '2026-09-18T14:00:00+05:30',
        'seed-user1-test-coverage-v1',
        'ACTIVE',
        '2026-09-18T14:00:00+05:30',
        '2026-09-18T14:00:00+05:30'
    ),
    (
        'evidence-user1-cicd',
        'user-1',
        'GITHUB',
        'cicd-standardisation-2026',
        'Standardised CI/CD configuration across 15 services',
        'Created reusable CI/CD configuration patterns across 15 services, reducing duplicated pipeline configuration by approximately 80%.',
        NULL,
        '2026-09-15T11:00:00+05:30',
        '2026-09-15T11:00:00+05:30',
        'seed-user1-cicd-v1',
        'ACTIVE',
        '2026-09-15T11:00:00+05:30',
        '2026-09-15T11:00:00+05:30'
    ),
    (
        'evidence-user1-architecture',
        'user-1',
        'DOCUMENT',
        'solution-architecture-proposal-2026',
        'Designed a solution architecture spanning API, execution and AI components',
        'Created a solution-level architecture for a new product flow spanning API, execution engine and AI assistant components, including service boundaries and integration responsibilities.',
        NULL,
        '2026-09-12T15:00:00+05:30',
        '2026-09-12T15:00:00+05:30',
        'seed-user1-architecture-v1',
        'ACTIVE',
        '2026-09-12T15:00:00+05:30',
        '2026-09-12T15:00:00+05:30'
    ),
    (
        'evidence-user1-planning',
        'user-1',
        'PERSONAL',
        'sprint-predictability-2026',
        'Improved sprint planning and delegation across a team of six',
        'Shifted focus toward planning and technical leadership, delegated implementation ownership and improved sprint predictability across a six-person engineering team.',
        NULL,
        '2026-09-10T17:00:00+05:30',
        '2026-09-10T17:00:00+05:30',
        'seed-user1-planning-v1',
        'ACTIVE',
        '2026-09-10T17:00:00+05:30',
        '2026-09-10T17:00:00+05:30'
    ),
    (
        'evidence-user1-alerting',
        'user-1',
        'GITHUB',
        'alerting-standardisation-2026',
        'Expanded reliability alerting across deployment and resource signals',
        'Added standard alerting patterns for CrashLoopBackOff, pod restarts, CPU pressure and deployment health to improve early detection of reliability issues.',
        NULL,
        '2026-09-08T13:00:00+05:30',
        '2026-09-08T13:00:00+05:30',
        'seed-user1-alerting-v1',
        'ACTIVE',
        '2026-09-08T13:00:00+05:30',
        '2026-09-08T13:00:00+05:30'
    ),
    (
        'evidence-user1-automation',
        'user-1',
        'DOCUMENT',
        'l2-automation-poc-2026',
        'Built an L2 operations automation proof of concept',
        'Designed a proof of concept to automate repeatable L2 operational tasks using documented procedures, workflow orchestration and controlled Kubernetes operations.',
        NULL,
        '2026-09-05T12:00:00+05:30',
        '2026-09-05T12:00:00+05:30',
        'seed-user1-automation-v1',
        'ACTIVE',
        '2026-09-05T12:00:00+05:30',
        '2026-09-05T12:00:00+05:30'
    ),
    (
        'evidence-user1-quality-gates',
        'user-1',
        'GITHUB',
        'quality-gates-2026',
        'Introduced automated quality gates for critical services',
        'Added automated validation checks to the delivery pipeline for critical services, preventing common quality regressions before deployment.',
        NULL,
        '2026-09-04T12:00:00+05:30',
        '2026-09-04T12:00:00+05:30',
        'seed-user1-quality-gates-v1',
        'ACTIVE',
        '2026-09-04T12:00:00+05:30',
        '2026-09-04T12:00:00+05:30'
    ),
    (
        'evidence-user1-code-smells',
        'user-1',
        'OTHER',
        'code-quality-cleanup-2026',
        'Reduced recurring code quality issues in core services',
        'Addressed recurring static-analysis findings and established a focused cleanup practice for core services.',
        NULL,
        '2026-09-03T12:00:00+05:30',
        '2026-09-03T12:00:00+05:30',
        'seed-user1-code-smells-v1',
        'ACTIVE',
        '2026-09-03T12:00:00+05:30',
        '2026-09-03T12:00:00+05:30'
    )
ON CONFLICT (id) DO UPDATE
SET
    user_id = EXCLUDED.user_id,
    source_type = EXCLUDED.source_type,
    source_id = EXCLUDED.source_id,
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    source_url = EXCLUDED.source_url,
    captured_at = EXCLUDED.captured_at,
    source_updated_at = EXCLUDED.source_updated_at,
    content_hash = EXCLUDED.content_hash,
    status = EXCLUDED.status,
    updated_at = EXCLUDED.updated_at;

-- -----------------------------------------------------------------------------
-- Evidence - user-2 (partial dataset)
-- -----------------------------------------------------------------------------

INSERT INTO evidence (
    id, user_id, source_type, source_id, title, description, source_url,
    captured_at, source_updated_at, content_hash, status, created_at, updated_at
)
VALUES
    (
        'evidence-user2-testing',
        'user-2',
        'GITHUB',
        'test-coverage-user2',
        'Improved automated test coverage from 55% to 68%',
        'Added unit tests for critical services and increased automated coverage by 13 percentage points.',
        NULL,
        '2026-09-20T12:00:00+05:30',
        '2026-09-20T12:00:00+05:30',
        'seed-user2-testing-v1',
        'ACTIVE',
        '2026-09-20T12:00:00+05:30',
        '2026-09-20T12:00:00+05:30'
    ),
    (
        'evidence-user2-delivery',
        'user-2',
        'JIRA',
        'delivery-predictability-user2',
        'Improved sprint commitment completion to 85%',
        'Improved sprint planning and technical breakdown, resulting in approximately 85% completion of committed sprint scope over the latest quarter.',
        NULL,
        '2026-09-18T12:00:00+05:30',
        '2026-09-18T12:00:00+05:30',
        'seed-user2-delivery-v1',
        'ACTIVE',
        '2026-09-18T12:00:00+05:30',
        '2026-09-18T12:00:00+05:30'
    )
ON CONFLICT (id) DO UPDATE
SET
    user_id = EXCLUDED.user_id,
    source_type = EXCLUDED.source_type,
    source_id = EXCLUDED.source_id,
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    source_url = EXCLUDED.source_url,
    captured_at = EXCLUDED.captured_at,
    source_updated_at = EXCLUDED.source_updated_at,
    content_hash = EXCLUDED.content_hash,
    status = EXCLUDED.status,
    updated_at = EXCLUDED.updated_at;

-- -----------------------------------------------------------------------------
-- Evidence versions
-- -----------------------------------------------------------------------------

INSERT INTO evidence_versions (
    id, evidence_id, version, content, content_hash, source_updated_at, captured_at, created_at
)
VALUES
    ('version-user1-monitoring-v1', 'evidence-user1-monitoring', 1,
     'Grafana monitoring coverage increased from 12 production workloads to 28 workloads. This represents a 133% increase in monitored workloads. Monitoring includes deployment health, CPU, memory and pod restart signals.',
     'seed-user1-monitoring-v1', '2026-09-30T10:00:00+05:30', '2026-09-30T10:00:00+05:30', '2026-09-30T10:00:00+05:30'),
    ('version-user1-incidents-v1', 'evidence-user1-incidents', 1,
     'More than 40 production incidents were investigated and resolved over a four-month period, including diagnosis, remediation and follow-up actions.',
     'seed-user1-incidents-v1', '2026-09-28T17:30:00+05:30', '2026-09-28T17:30:00+05:30', '2026-09-28T17:30:00+05:30'),
    ('version-user1-investigation-v1', 'evidence-user1-investigation', 1,
     'Average incident investigation time reduced from approximately 45 minutes to 25 minutes, representing a 44% reduction.',
     'seed-user1-investigation-v1', '2026-09-25T16:00:00+05:30', '2026-09-25T16:00:00+05:30', '2026-09-25T16:00:00+05:30'),
    ('version-user1-mentoring-v1', 'evidence-user1-mentoring', 1,
     'Technical guidance, design reviews and implementation support provided to six engineers across .NET and Go backend initiatives.',
     'seed-user1-mentoring-v1', '2026-09-22T18:00:00+05:30', '2026-09-22T18:00:00+05:30', '2026-09-22T18:00:00+05:30'),
    ('version-user1-test-coverage-v1', 'evidence-user1-test-coverage', 1,
     'Automated test coverage increased from 62% to 80%, an improvement of 18 percentage points.',
     'seed-user1-test-coverage-v1', '2026-09-18T14:00:00+05:30', '2026-09-18T14:00:00+05:30', '2026-09-18T14:00:00+05:30'),
    ('version-user1-cicd-v1', 'evidence-user1-cicd', 1,
     'Reusable CI/CD configuration patterns were introduced across 15 services, reducing duplicated pipeline configuration by approximately 80%.',
     'seed-user1-cicd-v1', '2026-09-15T11:00:00+05:30', '2026-09-15T11:00:00+05:30', '2026-09-15T11:00:00+05:30'),
    ('version-user1-architecture-v1', 'evidence-user1-architecture', 1,
     'A solution-level architecture was created for a product flow spanning API, execution engine and AI assistant components, including service boundaries and integration responsibilities.',
     'seed-user1-architecture-v1', '2026-09-12T15:00:00+05:30', '2026-09-12T15:00:00+05:30', '2026-09-12T15:00:00+05:30'),
    ('version-user1-planning-v1', 'evidence-user1-planning', 1,
     'Planning and technical leadership were increased across a six-person engineering team through clearer delegation, technical breakdown and sprint planning.',
     'seed-user1-planning-v1', '2026-09-10T17:00:00+05:30', '2026-09-10T17:00:00+05:30', '2026-09-10T17:00:00+05:30'),
    ('version-user1-alerting-v1', 'evidence-user1-alerting', 1,
     'Standard alerting patterns were added for CrashLoopBackOff, pod restarts, CPU pressure and deployment health.',
     'seed-user1-alerting-v1', '2026-09-08T13:00:00+05:30', '2026-09-08T13:00:00+05:30', '2026-09-08T13:00:00+05:30'),
    ('version-user1-automation-v1', 'evidence-user1-automation', 1,
     'A proof of concept was designed to automate repeatable L2 operational tasks using documented procedures, workflow orchestration and controlled Kubernetes operations.',
     'seed-user1-automation-v1', '2026-09-05T12:00:00+05:30', '2026-09-05T12:00:00+05:30', '2026-09-05T12:00:00+05:30'),
    ('version-user1-quality-gates-v1', 'evidence-user1-quality-gates', 1,
     'Automated validation checks were added to delivery pipelines for critical services to prevent common quality regressions before deployment.',
     'seed-user1-quality-gates-v1', '2026-09-04T12:00:00+05:30', '2026-09-04T12:00:00+05:30', '2026-09-04T12:00:00+05:30'),
    ('version-user1-code-smells-v1', 'evidence-user1-code-smells', 1,
     'Recurring static-analysis findings were addressed and a focused cleanup practice was established for core services.',
     'seed-user1-code-smells-v1', '2026-09-03T12:00:00+05:30', '2026-09-03T12:00:00+05:30', '2026-09-03T12:00:00+05:30'),
    ('version-user2-testing-v1', 'evidence-user2-testing', 1,
     'Automated test coverage increased from 55% to 68%, an improvement of 13 percentage points.',
     'seed-user2-testing-v1', '2026-09-20T12:00:00+05:30', '2026-09-20T12:00:00+05:30', '2026-09-20T12:00:00+05:30'),
    ('version-user2-delivery-v1', 'evidence-user2-delivery', 1,
     'Improved sprint planning resulted in approximately 85% completion of committed sprint scope over the latest quarter.',
     'seed-user2-delivery-v1', '2026-09-18T12:00:00+05:30', '2026-09-18T12:00:00+05:30', '2026-09-18T12:00:00+05:30')
ON CONFLICT (id) DO UPDATE
SET
    evidence_id = EXCLUDED.evidence_id,
    version = EXCLUDED.version,
    content = EXCLUDED.content,
    content_hash = EXCLUDED.content_hash,
    source_updated_at = EXCLUDED.source_updated_at,
    captured_at = EXCLUDED.captured_at,
    created_at = EXCLUDED.created_at;

-- -----------------------------------------------------------------------------
-- Evidence -> Goal mappings
-- -----------------------------------------------------------------------------

INSERT INTO evidence_mappings (
    id, evidence_id, goal_id, relevance, reason, confidence, created_at, updated_at
)
VALUES
    ('mapping-user1-monitoring-reliability', 'evidence-user1-monitoring', 'goal-user1-reliability', 'HIGH', 'Directly improves production observability and reliability coverage.', 0.97, '2026-09-30T10:05:00+05:30', '2026-09-30T10:05:00+05:30'),
    ('mapping-user1-incidents-reliability', 'evidence-user1-incidents', 'goal-user1-reliability', 'HIGH', 'Demonstrates sustained operational ownership and incident response.', 0.95, '2026-09-28T17:35:00+05:30', '2026-09-28T17:35:00+05:30'),
    ('mapping-user1-investigation-reliability', 'evidence-user1-investigation', 'goal-user1-reliability', 'HIGH', 'Shows measurable improvement in incident investigation efficiency.', 0.96, '2026-09-25T16:05:00+05:30', '2026-09-25T16:05:00+05:30'),
    ('mapping-user1-mentoring-leadership', 'evidence-user1-mentoring', 'goal-user1-leadership', 'HIGH', 'Direct evidence of mentoring and technical leadership across the team.', 0.98, '2026-09-22T18:05:00+05:30', '2026-09-22T18:05:00+05:30'),
    ('mapping-user1-testing-leadership', 'evidence-user1-test-coverage', 'goal-user1-leadership', 'MEDIUM', 'Demonstrates engineering quality leadership and improvement of team practices.', 0.88, '2026-09-18T14:05:00+05:30', '2026-09-18T14:05:00+05:30'),
    ('mapping-user1-cicd-architecture', 'evidence-user1-cicd', 'goal-user1-architecture', 'HIGH', 'Demonstrates platform-level standardisation across multiple services.', 0.95, '2026-09-15T11:05:00+05:30', '2026-09-15T11:05:00+05:30'),
    ('mapping-user1-architecture-architecture', 'evidence-user1-architecture', 'goal-user1-architecture', 'HIGH', 'Direct evidence of solution-level architecture capability.', 0.99, '2026-09-12T15:05:00+05:30', '2026-09-12T15:05:00+05:30'),
    ('mapping-user1-planning-leadership', 'evidence-user1-planning', 'goal-user1-leadership', 'HIGH', 'Shows increased leadership responsibility through planning and delegation.', 0.94, '2026-09-10T17:05:00+05:30', '2026-09-10T17:05:00+05:30'),
    ('mapping-user1-alerting-reliability', 'evidence-user1-alerting', 'goal-user1-reliability', 'HIGH', 'Directly strengthens early detection of reliability issues.', 0.96, '2026-09-08T13:05:00+05:30', '2026-09-08T13:05:00+05:30'),
    ('mapping-user1-automation-architecture', 'evidence-user1-automation', 'goal-user1-architecture', 'HIGH', 'Demonstrates automation and solution design beyond individual implementation.', 0.91, '2026-09-05T12:05:00+05:30', '2026-09-05T12:05:00+05:30'),
    ('mapping-user1-quality-gates-quality', 'evidence-user1-quality-gates', 'goal-user1-quality', 'HIGH', 'Directly supports safer and more consistent engineering delivery.', 0.94, '2026-09-04T12:05:00+05:30', '2026-09-04T12:05:00+05:30'),
    ('mapping-user1-code-smells-quality', 'evidence-user1-code-smells', 'goal-user1-quality', 'HIGH', 'Demonstrates sustained attention to engineering quality and maintainability.', 0.92, '2026-09-03T12:05:00+05:30', '2026-09-03T12:05:00+05:30'),
    ('mapping-user2-testing-quality', 'evidence-user2-testing', 'goal-user2-quality', 'HIGH', 'Directly supports the engineering quality goal.', 0.97, '2026-09-20T12:05:00+05:30', '2026-09-20T12:05:00+05:30'),
    ('mapping-user2-delivery-delivery', 'evidence-user2-delivery', 'goal-user2-delivery', 'HIGH', 'Directly supports improved delivery predictability.', 0.96, '2026-09-18T12:05:00+05:30', '2026-09-18T12:05:00+05:30')
ON CONFLICT (id) DO UPDATE
SET
    evidence_id = EXCLUDED.evidence_id,
    goal_id = EXCLUDED.goal_id,
    relevance = EXCLUDED.relevance,
    reason = EXCLUDED.reason,
    confidence = EXCLUDED.confidence,
    updated_at = EXCLUDED.updated_at;

-- -----------------------------------------------------------------------------
-- Impact assessments - user-1
-- -----------------------------------------------------------------------------

INSERT INTO impact_assessments (
    id, evidence_id, goal_id, impact_type, impact_summary,
    impact_score, confidence, assessment_version, created_at, updated_at
)
VALUES
    ('impact-user1-monitoring', 'evidence-user1-monitoring', 'goal-user1-reliability', 'RELIABILITY', 'Expanded monitoring coverage from 12 to 28 workloads, materially improving visibility into production health and early detection of reliability issues.', 0.92, 0.96, 1, '2026-09-30T11:00:00+05:30', '2026-09-30T11:00:00+05:30'),
    ('impact-user1-incidents', 'evidence-user1-incidents', 'goal-user1-reliability', 'OPERATIONAL', 'Resolving more than 40 production incidents demonstrates sustained operational ownership and improved service continuity.', 0.90, 0.95, 1, '2026-09-28T18:00:00+05:30', '2026-09-28T18:00:00+05:30'),
    ('impact-user1-investigation', 'evidence-user1-investigation', 'goal-user1-reliability', 'PERFORMANCE', 'Reducing average investigation time by 44% improves the speed at which production issues can be diagnosed and resolved.', 0.88, 0.94, 1, '2026-09-25T17:00:00+05:30', '2026-09-25T17:00:00+05:30'),
    ('impact-user1-mentoring', 'evidence-user1-mentoring', 'goal-user1-leadership', 'MENTORING', 'Mentoring six engineers increases team capability and creates leverage beyond the individuals directly implementing the work.', 0.91, 0.97, 1, '2026-09-22T19:00:00+05:30', '2026-09-22T19:00:00+05:30'),
    ('impact-user1-testing', 'evidence-user1-test-coverage', 'goal-user1-leadership', 'TECHNICAL', 'Increasing automated test coverage from 62% to 80% strengthens engineering quality and encourages sustainable development practices.', 0.84, 0.90, 1, '2026-09-18T15:00:00+05:30', '2026-09-18T15:00:00+05:30'),
    ('impact-user1-cicd', 'evidence-user1-cicd', 'goal-user1-architecture', 'AUTOMATION', 'Standardising CI/CD across 15 services reduces duplicated configuration and establishes a reusable platform engineering pattern.', 0.93, 0.95, 1, '2026-09-15T12:00:00+05:30', '2026-09-15T12:00:00+05:30'),
    ('impact-user1-architecture', 'evidence-user1-architecture', 'goal-user1-architecture', 'INNOVATION', 'Designing boundaries across API, execution and AI components demonstrates solution-level thinking and progression toward architecture responsibility.', 0.94, 0.98, 1, '2026-09-12T16:00:00+05:30', '2026-09-12T16:00:00+05:30'),
    ('impact-user1-planning', 'evidence-user1-planning', 'goal-user1-leadership', 'LEADERSHIP', 'Improved planning and delegation across a six-person team demonstrates increased leadership leverage and ownership beyond individual coding tasks.', 0.92, 0.94, 1, '2026-09-10T18:00:00+05:30', '2026-09-10T18:00:00+05:30'),
    ('impact-user1-alerting', 'evidence-user1-alerting', 'goal-user1-reliability', 'RELIABILITY', 'Standardised alerts for deployment and resource signals strengthen proactive detection and operational resilience.', 0.89, 0.94, 1, '2026-09-08T14:00:00+05:30', '2026-09-08T14:00:00+05:30'),
    ('impact-user1-automation', 'evidence-user1-automation', 'goal-user1-architecture', 'AUTOMATION', 'The L2 automation proof of concept demonstrates the ability to translate operational processes into a controlled technical solution.', 0.87, 0.89, 1, '2026-09-05T13:00:00+05:30', '2026-09-05T13:00:00+05:30')
ON CONFLICT (id) DO UPDATE
SET
    evidence_id = EXCLUDED.evidence_id,
    goal_id = EXCLUDED.goal_id,
    impact_type = EXCLUDED.impact_type,
    impact_summary = EXCLUDED.impact_summary,
    impact_score = EXCLUDED.impact_score,
    confidence = EXCLUDED.confidence,
    assessment_version = EXCLUDED.assessment_version,
    updated_at = EXCLUDED.updated_at;

-- -----------------------------------------------------------------------------
-- Impact assessments - user-1 quality examples
-- -----------------------------------------------------------------------------

INSERT INTO impact_assessments (
    id, evidence_id, goal_id, impact_type, impact_summary,
    impact_score, confidence, assessment_version, created_at, updated_at
)
VALUES
    ('impact-user1-quality-gates', 'evidence-user1-quality-gates', 'goal-user1-quality', 'RELIABILITY', 'Automated quality gates catch common regressions before deployment and improve confidence in delivery.', 0.82, 0.91, 1, '2026-09-04T13:00:00+05:30', '2026-09-04T13:00:00+05:30'),
    ('impact-user1-code-smells', 'evidence-user1-code-smells', 'goal-user1-quality', 'TECHNICAL', 'Reducing recurring code quality issues improves maintainability and lowers the risk of repeated engineering defects.', 0.80, 0.89, 1, '2026-09-03T13:00:00+05:30', '2026-09-03T13:00:00+05:30')
ON CONFLICT (id) DO UPDATE
SET
    evidence_id = EXCLUDED.evidence_id,
    goal_id = EXCLUDED.goal_id,
    impact_type = EXCLUDED.impact_type,
    impact_summary = EXCLUDED.impact_summary,
    impact_score = EXCLUDED.impact_score,
    confidence = EXCLUDED.confidence,
    assessment_version = EXCLUDED.assessment_version,
    updated_at = EXCLUDED.updated_at;

-- -----------------------------------------------------------------------------
-- Impact assessments - user-2
-- -----------------------------------------------------------------------------

INSERT INTO impact_assessments (
    id, evidence_id, goal_id, impact_type, impact_summary,
    impact_score, confidence, assessment_version, created_at, updated_at
)
VALUES
    ('impact-user2-testing', 'evidence-user2-testing', 'goal-user2-quality', 'TECHNICAL', 'Increasing test coverage by 13 percentage points improves confidence in changes to critical services.', 0.74, 0.91, 1, '2026-09-20T13:00:00+05:30', '2026-09-20T13:00:00+05:30')
ON CONFLICT (id) DO UPDATE
SET
    evidence_id = EXCLUDED.evidence_id,
    goal_id = EXCLUDED.goal_id,
    impact_type = EXCLUDED.impact_type,
    impact_summary = EXCLUDED.impact_summary,
    impact_score = EXCLUDED.impact_score,
    confidence = EXCLUDED.confidence,
    assessment_version = EXCLUDED.assessment_version,
    updated_at = EXCLUDED.updated_at;

COMMIT;

-- Expected rich dataset for user-1:
--   5 active goals
--   goal-user1-not-started -> 0 achievements / 0 evidence / 0 impact
--   goal-user1-quality -> 2 achievements / 2 evidence / 2 impact
--   goal-user1-architecture -> 3 achievements / 3 evidence / 3 impact
--   goal-user1-leadership -> 3 achievements / 3 evidence / 3 impact
--   goal-user1-reliability -> 4+ achievements / 4+ evidence / 4+ impact
--   12 evidence records
--   12 evidence mappings
--   12 impact assessments
--
-- Expected partial dataset for user-2:
--   2 active goals
--   2 evidence records
--   2 evidence mappings
--   1 impact assessment
--
-- user-empty intentionally has no goals, evidence or impact data.
