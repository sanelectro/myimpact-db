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

A push changing `migrations/**` triggers GitHub Actions.

The workflow runs:

```text
Flyway validate
    ↓
Flyway migrate
```

using:

```text
FLYWAY_URL
FLYWAY_USER
FLYWAY_PASSWORD
```

from GitHub repository/environment secrets.

## Important

Do not put `BEGIN` or `COMMIT` in migration files; Flyway manages the transaction boundary.

Do not edit a migration after it has been applied. Create another timestamped versioned migration.
