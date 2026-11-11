# MyImpact DB Migration Workflow

## Fresh local database

```bash
cp .env.example .env
docker compose up -d postgres
docker compose run --rm flyway
docker compose ps
```

The first migration is:

```text
migrations/V20260919150000__initial_schema.sql
```

## Existing local database managed by this repository

```bash
./scripts/db/status.sh
./scripts/db/validate.sh
./scripts/db/migrate.sh
./scripts/db/status.sh
```

## Create a migration

```bash
./scripts/db/new_migration.sh "add document artifact path"
```

Then edit the generated SQL file.

Validate:

```bash
./scripts/db/validate.sh
```

Apply:

```bash
./scripts/db/migrate.sh
```

Check status:

```bash
./scripts/db/status.sh
```

## CI/CD

Pushes do not trigger GitHub Actions migrations. For now, run migrations
manually against the local development database using the commands above.

The GitHub workflow remains available through manual dispatch and runs:

```text
Flyway info
    ↓
Flyway migrate
    ↓
Flyway validate
```

using:

```text
FLYWAY_URL
FLYWAY_USER
FLYWAY_PASSWORD
```

from GitHub repository/environment secrets.

Manual dispatch applies migrations to the configured target; verify the target
before starting it. A GitHub-hosted runner does not automatically have access
to the PostgreSQL container on your computer.

## Important

Do not put `BEGIN` or `COMMIT` in migration files; Flyway manages the transaction boundary.

Do not edit a migration after it has been applied. Create another timestamped versioned migration.

## Goal hierarchy writer protocol

The hierarchy migration adds optional goal levels and parents, a relationship
revision, and append-only relationship events. Existing goals retain a null
level and parent. A parent must belong to the same owner; deleting a parent
with children is restricted.

Every transaction that changes a parent must use READ COMMITTED isolation,
acquire `pg_advisory_xact_lock(1296650324, 1)` in a separate statement before
reading hierarchy state, and set the transaction-local
`myimpact.relationship_actor` to the owner's user ID. An optional
`myimpact.relationship_reason` may also be set transaction-locally. The writer
must then compare the expected relationship revision and update only if it
matches. The database checks the lock, actor, ownership, and cycle constraints,
increments the revision, and records the event in the same transaction. A
same-parent update does not increment the revision or create an event.

The lock must precede the statement that reads or updates the hierarchy: taking
it inside an update does not guarantee a fresh READ COMMITTED snapshot.
Relationship changes do not create goal-definition versions. These schema
facilities do not themselves expose a hierarchy API.

Run `tests/goal_hierarchy.sql` only against a disposable migrated PostgreSQL
database. The concurrency test requires a container labelled
`myimpact.test=hierarchy-disposable`, with the test database and user named
`hierarchytest`; set `HIERARCHY_TEST_CONTAINER` to that container and run
`python -m unittest discover -s tests -p test_goal_hierarchy_concurrency.py -v`.

## Goal operative-version foundation

The operative-version migration adds a nullable pointer constrained to a
version of the same Goal. It does not choose a version for existing Goals or
change the behavior of existing readers and writers. The pointer alone does
not implement publication, protect the live projection, or prevent history
deletion.

The subsequent definition-kind migration classifies existing snapshots as
`STANDARD` and permits immutable `PROPOSAL` snapshots. Legacy latest-version
readers exclude `PROPOSAL` snapshots. No proposal creation or publication
workflow is enabled by these migrations. Before publication is enabled,
readers and writers must be changed to honor the selected operative version,
including when it is a proposal, and evidence safeguards must be enforced.

The proposal-head and command-receipt migration adds same-Goal references,
proposal-kind validation, and immutable completed retry receipts. It does not
select baselines, create proposals, or enable publication. Receipts currently
support only the internal definition-preparation command. Existing Goal
deletion behavior is unchanged; these tables do not by themselves guarantee
permanent history retention.

The baseline-observation migration adds a same-Goal observation record with
explicitly unknown historical effectivity. It does not choose or backfill any
Goal version, assert historical approval, or change existing Goal projections.
Observations may still be removed by existing cascading Goal/user deletion.

The observed-baseline version migration permits `OBSERVED` snapshots and
records their same-Goal `STANDARD` source version. Existing observations and
Goals are unchanged. Existing latest-standard reads continue to exclude
observed snapshots. An observation records current content, not historical
approval or a proven past effective period; it does not enable publication.

Run `tests/goal_operative_version.sql` and
`tests/goal_definition_version_kind.sql` only against a disposable database named
`hierarchytest`, after creating its synthetic `phase1-upgrade-goal` and
`phase1-upgrade-version` fixture on the previous migration baseline and then
applying the foundation migrations. The SQL tests roll their own changes back.
