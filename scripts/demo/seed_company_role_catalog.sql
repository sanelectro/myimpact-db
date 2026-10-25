-- Demo-only role catalogue for comparing company isolation.
-- Re-running this script replaces only the seeded role catalogue for the two
-- demo companies; it does not create audit events.

BEGIN;

INSERT INTO organizations (id, name, normalized_name, created_at)
VALUES
    (
        'organization-myimpact-demo',
        'MyImpact Demo Engineering',
        'myimpact-demo-engineering',
        CURRENT_TIMESTAMP
    ),
    (
        'organization-role-catalog-northstar',
        'Northstar Product Labs',
        'northstar-product-labs',
        CURRENT_TIMESTAMP
    )
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    normalized_name = EXCLUDED.normalized_name;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM organizations WHERE id = 'organization-myimpact-demo'
    ) OR NOT EXISTS (
        SELECT 1 FROM organizations WHERE id = 'organization-role-catalog-northstar'
    ) THEN
        RAISE EXCEPTION 'Run seed_demo_data.sh before seeding the role catalogue.';
    END IF;
END;
$$;

DELETE FROM organization_role_audit_events
WHERE organization_id IN (
    'organization-myimpact-demo',
    'organization-role-catalog-northstar'
)
AND role_id LIKE 'demo-role-catalog-%';

DELETE FROM organization_roles
WHERE organization_id IN (
    'organization-myimpact-demo',
    'organization-role-catalog-northstar'
)
AND id LIKE 'demo-role-catalog-%';

CREATE TEMPORARY TABLE demo_role_catalog_templates (
    slug VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,
    summary TEXT NOT NULL,
    responsibilities JSONB NOT NULL,
    goals JSONB NOT NULL,
    competencies JSONB NOT NULL
) ON COMMIT DROP;

INSERT INTO demo_role_catalog_templates (
    slug, name, summary, responsibilities, goals, competencies
)
VALUES
    (
        'intern-software-engineer',
        'Intern Software Engineer',
        'Learn professional software delivery while contributing to scoped work with guidance.',
        $json$[
            "Build foundational coding skills and apply direction to well-defined tasks.",
            "Learn the software delivery lifecycle, version control, and Agile practices.",
            "Contribute to coding, bug fixing, testing, documentation, research, or support.",
            "Practice debugging, logging, team conventions, and basic testing.",
            "Communicate progress and challenges, participate in reviews, and apply feedback.",
            "Document work and share useful learnings with the team."
        ]$json$::jsonb,
        $json$[
            {"title":"Contribute to a scoped engineering task","description":"Complete an assigned development, bug-fix, or support task with guidance and communicate blockers early."},
            {"title":"Practice testing and debugging fundamentals","description":"Add basic tests to assigned work and use team tools and conventions to investigate simple issues."},
            {"title":"Document internship learning","description":"Record how assigned work moves through the team development process and share useful learnings with teammates."}
        ]$json$::jsonb,
        '[]'::jsonb
    ),
    (
        'associate-software-engineer',
        'Associate Software Engineer',
        'Build software-development foundations and contribute to team outcomes with support and feedback.',
        $json$[
            "Write simple, maintainable code with the team's languages, tools, and frameworks.",
            "Complete assigned work on time and to agreed quality standards, raising challenges early.",
            "Learn testing, debugging, version control, coding conventions, and engineering practices.",
            "Collaborate with engineers, testers, and product managers; communicate progress and review work.",
            "Document solutions, processes, and learnings that can help the team.",
            "Seek mentorship and apply constructive feedback."
        ]$json$::jsonb,
        $json$[
            {"title":"Deliver scoped engineering tasks reliably","description":"Complete assigned components with appropriate guidance, quality, and timely communication."},
            {"title":"Strengthen code quality and testing habits","description":"Apply team conventions, write basic tests, and use review feedback to improve submitted work."},
            {"title":"Grow technical capability and team knowledge","description":"Seek mentorship, build familiarity with team tools, and document useful learnings."}
        ]$json$::jsonb,
        $json$[
            {"name":"Primary programming language","expected_level":"Basic","description":"Apply the primary language to scoped changes with guidance."},
            {"name":"Test automation","expected_level":"Basic","description":"Write and run basic automated tests for assigned work."},
            {"name":"Agile principles and methods","expected_level":"Basic","description":"Participate in team planning and delivery practices."}
        ]$json$::jsonb
    ),
    (
        'software-engineer',
        'Software Engineer',
        'Deliver software that meets user and business needs through sound implementation and continuous improvement.',
        $json$[
            "Analyze problems and implement clean, maintainable, tested, and secure code.",
            "Contribute to feature planning and estimation; surface delivery risks early.",
            "Work with engineering, product, design, and partner teams to clarify requirements.",
            "Participate in code reviews, resolve defects, and consider performance and reliability.",
            "Improve the codebase through appropriate refactoring and optimization.",
            "Maintain technical documentation and share knowledge with the team."
        ]$json$::jsonb,
        $json$[
            {"title":"Deliver maintainable and secure features","description":"Implement agreed product functionality with appropriate tests and review."},
            {"title":"Improve delivery planning and collaboration","description":"Contribute to estimates, communicate progress and risks, and align implementation with user needs."},
            {"title":"Strengthen software quality and reliability","description":"Resolve relevant defects and improve testing, documentation, performance, or security in owned components."}
        ]$json$::jsonb,
        $json$[
            {"name":"Primary programming language","expected_level":"Advanced","description":"Implement maintainable features in the team's primary language."},
            {"name":"Test automation","expected_level":"Advanced","description":"Create and maintain automated tests for product changes."},
            {"name":"Agile principles and methods","expected_level":"Advanced","description":"Contribute effectively to iterative planning and delivery."},
            {"name":"Cyber security","expected_level":"Advanced","description":"Apply secure development practices to implementation and review."},
            {"name":"Cloud patterns","expected_level":"Basic","description":"Understand the cloud patterns used by the team's services."},
            {"name":"Primary platform","expected_level":"Advanced","description":"Develop and support applications on the team's primary platform."}
        ]$json$::jsonb
    ),
    (
        'senior-software-engineer',
        'Senior Software Engineer',
        'Apply deep technical judgment to complex work while strengthening the wider team.',
        $json$[
            "Design scalable, secure, and robust systems and collaborate with architects.",
            "Own substantial work through delivery while balancing technical trade-offs.",
            "Review code, provide constructive feedback, and mentor engineers.",
            "Contribute to sustainable planning with engineering managers and product partners.",
            "Improve development processes, quality, testing, performance, and reliability.",
            "Document designs and communicate technical topics clearly.",
            "Align technical contributions with business goals and product direction."
        ]$json$::jsonb,
        $json$[
            {"title":"Lead robust technical design","description":"Shape a system or feature design with documented trade-offs and appropriate architectural collaboration."},
            {"title":"Own a substantial delivery end to end","description":"Plan and deliver a multi-week technical initiative with appropriate quality and stakeholder communication."},
            {"title":"Grow engineering capability through mentorship","description":"Provide actionable review feedback and support teammates' technical development."}
        ]$json$::jsonb,
        $json$[
            {"name":"Primary programming language","expected_level":"Expert","description":"Make sound implementation choices and guide quality in the primary language."},
            {"name":"Test automation","expected_level":"Expert","description":"Guide effective test strategies for complex systems."},
            {"name":"Agile principles and methods","expected_level":"Expert","description":"Improve team execution through strong iterative practices."},
            {"name":"Cyber security","expected_level":"Advanced","description":"Address security risks in system and feature design."},
            {"name":"Cloud patterns","expected_level":"Advanced","description":"Apply cloud patterns to scalable and reliable services."},
            {"name":"Primary platform","expected_level":"Expert","description":"Provide technical direction for the team's primary platform."}
        ]$json$::jsonb
    ),
    (
        'lead-software-engineer',
        'Lead Software Engineer',
        'Provide hands-on technical leadership and guide a team toward high-quality software outcomes.',
        $json$[
            "Shape scalable and maintainable designs and guide implementation standards.",
            "Tackle complex technical problems and model high-quality code and review practices.",
            "Mentor engineers and communicate technical decisions to stakeholders.",
            "Break work into manageable tasks, prioritize delivery, and identify risks early.",
            "Improve delivery processes, testing, reliability, and feedback practices.",
            "Connect team technical work to business priorities and consider cost.",
            "Balance hands-on engineering with team leadership responsibilities."
        ]$json$::jsonb,
        $json$[
            {"title":"Improve team technical direction and quality","description":"Guide a design or engineering-practice improvement with appropriate architectural alignment."},
            {"title":"Strengthen predictable team delivery","description":"Improve planning, work breakdown, prioritization, or risk management for team commitments."},
            {"title":"Develop engineers and align work to outcomes","description":"Mentor teammates and connect technical decisions to stakeholder needs and business goals."}
        ]$json$::jsonb,
        $json$[
            {"name":"Primary programming language","expected_level":"Expert","description":"Set a high standard for implementation and technical review."},
            {"name":"Test automation","expected_level":"Expert","description":"Guide quality practices and automated testing across team work."},
            {"name":"Agile principles and methods","expected_level":"Expert","description":"Strengthen planning and delivery practices across the team."},
            {"name":"Cyber security","expected_level":"Expert","description":"Lead secure engineering practices for team-owned systems."},
            {"name":"Cloud patterns","expected_level":"Expert","description":"Guide use of cloud patterns in team architecture and delivery."},
            {"name":"Primary platform","expected_level":"Expert","description":"Provide technical direction for the team's primary platform."}
        ]$json$::jsonb
    ),
    (
        'principal-software-engineer',
        'Principal Software Engineer',
        'Extend technical leadership across teams through strategic architecture and engineering culture.',
        $json$[
            "Guide high-level architecture across projects and develop a long-term technology vision.",
            "Partner with product, engineering, architecture, and executive stakeholders on technical strategy.",
            "Address cross-team challenges and manage stability, security, performance, and scalability risks.",
            "Promote engineering practices such as code quality, testing, CI/CD, and DevOps.",
            "Mentor senior engineers and emerging technical leaders.",
            "Contribute to long-term roadmaps and represent engineering excellence."
        ]$json$::jsonb,
        $json$[
            {"title":"Set cross-project technical direction","description":"Guide an architectural or technology decision across projects and communicate its alignment with long-term goals."},
            {"title":"Resolve a cross-team technical challenge","description":"Coordinate a sustainable response to a complex issue affecting multiple teams or products."},
            {"title":"Scale engineering practices and technical leadership","description":"Strengthen a shared engineering practice and mentor senior engineers or emerging technical leaders."}
        ]$json$::jsonb,
        '[]'::jsonb
    ),
    (
        'lead-ux-designer',
        'Lead UX Designer',
        'Set user-centered design direction across products while balancing hands-on design and team leadership.',
        $json$[
            "Advocate for user needs and align design direction with business goals.",
            "Design complex workflows and validate them with research and usability testing.",
            "Build and maintain design systems that support consistency and scale.",
            "Collaborate with product managers, developers, and stakeholders; communicate design rationale.",
            "Mentor designers, lead design reviews, and connect work to measurable user value.",
            "Deliver intuitive, accessible experiences and improve design workflows."
        ]$json$::jsonb,
        $json$[
            {"title":"Improve a user-centered product experience","description":"Validate and refine a complex workflow using user research or usability testing."},
            {"title":"Strengthen design-system consistency and accessibility","description":"Improve reusable design-system guidance and apply it across relevant product experiences."},
            {"title":"Grow design practice and measurable user value","description":"Mentor designers, lead collaborative reviews, and connect design outcomes to user needs."}
        ]$json$::jsonb,
        $json$[
            {"name":"Design research techniques","expected_level":"Expert","description":"Lead research approaches that inform product design decisions."},
            {"name":"Interaction design techniques","expected_level":"Expert","description":"Guide interaction design for complex user workflows."},
            {"name":"Usability engineering","expected_level":"Expert","description":"Validate and improve usability through structured evaluation."},
            {"name":"Strategy and roadmapping","expected_level":"Expert","description":"Set and communicate design direction aligned with product priorities."}
        ]$json$::jsonb
    );

INSERT INTO organization_roles (
    id, organization_id, name, normalized_name, summary,
    created_by_user_id, created_at, updated_at
)
SELECT
    'demo-role-catalog-' || template.slug || '-' || company.company_key,
    company.id,
    template.name,
    lower(template.name),
    company.name || ' / ' || template.summary,
    NULL,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM demo_role_catalog_templates AS template
CROSS JOIN (
    SELECT id, name, 'myimpact' AS company_key
    FROM organizations
    WHERE id = 'organization-myimpact-demo'
    UNION ALL
    SELECT id, name, 'northstar' AS company_key
    FROM organizations
    WHERE id = 'organization-role-catalog-northstar'
) AS company;

INSERT INTO organization_role_responsibilities (id, role_id, statement, position)
SELECT
    'demo-role-resp-' || md5(role.id || ':' || item.position),
    role.id,
    item.statement,
    (item.position - 1)::integer
FROM demo_role_catalog_templates AS template
CROSS JOIN (
    SELECT id, organization_id, name
    FROM organization_roles
    WHERE id LIKE 'demo-role-catalog-%'
      AND organization_id IN (
          'organization-myimpact-demo',
          'organization-role-catalog-northstar'
      )
) AS role
CROSS JOIN LATERAL jsonb_array_elements_text(template.responsibilities)
    WITH ORDINALITY AS item(statement, position)
WHERE role.name = template.name;

INSERT INTO organization_role_goals (id, role_id, title, description, position)
SELECT
    'demo-role-goal-' || md5(role.id || ':' || item.position),
    role.id,
    item.goal->>'title',
    item.goal->>'description',
    (item.position - 1)::integer
FROM demo_role_catalog_templates AS template
CROSS JOIN (
    SELECT id, organization_id, name
    FROM organization_roles
    WHERE id LIKE 'demo-role-catalog-%'
      AND organization_id IN (
          'organization-myimpact-demo',
          'organization-role-catalog-northstar'
      )
) AS role
CROSS JOIN LATERAL jsonb_array_elements(template.goals)
    WITH ORDINALITY AS item(goal, position)
WHERE role.name = template.name;

INSERT INTO organization_role_competencies (
    id, role_id, name, expected_level, description, position
)
SELECT
    'demo-role-competency-' || md5(role.id || ':' || item.position),
    role.id,
    item.competency->>'name',
    item.competency->>'expected_level',
    item.competency->>'description',
    (item.position - 1)::integer
FROM demo_role_catalog_templates AS template
CROSS JOIN (
    SELECT id, organization_id, name
    FROM organization_roles
    WHERE id LIKE 'demo-role-catalog-%'
      AND organization_id IN (
          'organization-myimpact-demo',
          'organization-role-catalog-northstar'
      )
) AS role
CROSS JOIN LATERAL jsonb_array_elements(template.competencies)
    WITH ORDINALITY AS item(competency, position)
WHERE role.name = template.name;

COMMIT;
