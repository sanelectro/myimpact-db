# Versioned SQL Migrations

All MyImpact database changes are versioned SQL migrations.

## Naming

```text
VYYYYMMDDHHMMSS__short_description.sql
```

Examples:

```text
V20260919150000__initial_schema.sql
V20260920100000__add_document_artifact_path.sql
V20261001100000__create_calculate_impact_function.sql
V20261015110000__update_calculate_impact_function.sql
```

## Rules

1. Create a new migration for every database change.
2. Never edit an already-applied migration.
3. Procedure/function/view/trigger changes also get a new versioned migration.
4. Use `CREATE OR REPLACE` where appropriate, but put it in a new migration.
5. Do not add `BEGIN`/`COMMIT` wrappers to migrations; Flyway manages the migration transaction.
