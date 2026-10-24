# myimpact-db

SQL-first, versioned-only database repository for MyImpact.

## Design

- Flyway is the migration engine.
- Migrations are plain SQL.
- Every database change gets a new timestamped version.
- Applied migrations are immutable.
- Stored procedures, functions, views, and triggers use new versioned SQL migrations too.

## Structure

```text
myimpact-db/
├── migrations/
│   └── V20260919150000__initial_schema.sql
├── scripts/
│   └── db/
│       ├── new_migration.sh
│       ├── status.sh
│       ├── validate.sh
│       └── migrate.sh
├── docker-compose.yml
├── .env.example
└── .github/
    └── workflows/
        └── database-migrations.yml
```

## Local database

```bash
cp .env.example .env
docker compose up -d postgres
```

The default local port is `5556`.

Run the migrations:

```bash
docker compose run --rm flyway
```

Or, against the local PostgreSQL using the helper script:

```bash
./scripts/db/migrate.sh
```

Check status:

```bash
./scripts/db/status.sh
```

Validate:

```bash
./scripts/db/validate.sh
```

## New migration

```bash
./scripts/db/new_migration.sh "add document artifact path"
```

Edit the generated SQL, validate it, run it, then commit it.

```bash
./scripts/db/validate.sh
./scripts/db/migrate.sh
./scripts/db/status.sh
```

## CI/CD

`.github/workflows/database-migrations.yml` runs Flyway when `migrations/**` changes.

Required GitHub secrets:

```text
FLYWAY_URL
FLYWAY_USER
FLYWAY_PASSWORD
```

The same migration repository is promoted through environments; only the target connection values change.

## Migration rules

Never edit an applied migration.

For example:

```text
V20261001100000__create_calculate_impact_function.sql
V20261015110000__update_calculate_impact_function.sql
```

For PostgreSQL functions/procedures, use `CREATE OR REPLACE` inside the new migration when appropriate.

Do not add `BEGIN`/`COMMIT` to migration files because Flyway controls migration transactions.

## Fresh database reset

For local testing only:

```bash
docker compose down -v
docker compose up -d postgres
docker compose run --rm flyway
```

`down -v` deletes the local PostgreSQL data volume.

## Local demo dataset

After migrations, seed the role-based demo accounts, goals, source evidence,
impact assessments, and PDF evidence assets:

```bash
export DEMO_USER_PASSWORD='choose-a-local-password-at-least-12-chars'
./scripts/demo/seed_demo_data.sh
```

Each employee persona receives personal, team, and organization goals: one
active, one approved, and one draft goal. The active focus goal has related
GitHub, Jira, and written evidence; organization goals are associated with the
shared demo organization.

The nine employee accounts and `myimpact-admin@example.com` all use that
password. The admin account has MyImpact-wide platform access and is not
associated with a customer company. The script requires the authentication
service virtual environment at `myimpact-api/.venv`; override it with
`MYIMPACT_AUTH_PYTHON` if needed. It refuses to seed a remote database unless
`ALLOW_REMOTE_DEMO_SEED=true` is explicitly set. The PDFs are served by the UI
from `myimpact-web/public/demo-evidence/`.
