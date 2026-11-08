import os
import subprocess
import unittest
from concurrent.futures import ThreadPoolExecutor
from uuid import uuid4


class GoalHierarchyConcurrencyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.container = os.environ.get("HIERARCHY_TEST_CONTAINER")
        if not cls.container:
            raise unittest.SkipTest("Set HIERARCHY_TEST_CONTAINER to a disposable test container")
        label = subprocess.run(
            ["docker", "inspect", "--format", '{{index .Config.Labels "myimpact.test"}}', cls.container],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        if label != "hierarchy-disposable":
            raise RuntimeError("The target container is not labelled as a disposable hierarchy test")

    def sql(self, sql):
        return subprocess.run(
            [
                "docker", "exec", "-i", self.container, "psql", "-X", "-q",
                "-v", "ON_ERROR_STOP=1", "-U", "hierarchytest", "-d", "hierarchytest",
            ],
            input=sql,
            capture_output=True,
            text=True,
        )

    def test_concurrent_reverse_links_cannot_create_a_cycle(self):
        suffix = uuid4().hex
        owner, first, second = f"owner-{suffix}", f"a-{suffix}", f"b-{suffix}"
        setup = self.sql(f"""
            INSERT INTO users (id, name, email, created_at, updated_at)
            VALUES ('{owner}', 'Owner', '{owner}@example.test', now(), now());
            INSERT INTO goals (id, user_id, title, status, created_at, updated_at)
            VALUES ('{first}', '{owner}', 'A', 'DRAFT', now(), now()),
                   ('{second}', '{owner}', 'B', 'DRAFT', now(), now());
        """)
        self.assertEqual(setup.returncode, 0, setup.stderr)

        def link(child, parent):
            return self.sql(f"""
                BEGIN;
                SELECT pg_advisory_xact_lock(1296650324, 1);
                SELECT pg_sleep(1);
                SELECT set_config('myimpact.relationship_actor', '{owner}', true);
                UPDATE goals SET parent_goal_id = '{parent}' WHERE id = '{child}';
                COMMIT;
            """)

        with ThreadPoolExecutor(max_workers=2) as executor:
            results = list(executor.map(lambda pair: link(*pair), [(first, second), (second, first)]))

        self.assertEqual(sorted(result.returncode == 0 for result in results), [False, True])
        self.assertIn("Goal hierarchy cannot contain cycles", next(r.stderr for r in results if r.returncode))
        verification = self.sql(f"""
            DO $$
            BEGIN
                IF (SELECT count(*) FROM goals WHERE id IN ('{first}', '{second}')
                    AND parent_goal_id IS NOT NULL) <> 1
                   OR (SELECT count(*) FROM goal_relationship_events WHERE goal_id IN ('{first}', '{second}')) <> 1
                THEN
                    RAISE EXCEPTION 'Concurrent updates left an invalid hierarchy';
                END IF;
            END $$;
        """)
        self.assertEqual(verification.returncode, 0, verification.stderr)
