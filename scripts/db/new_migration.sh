#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo 'Usage: ./scripts/db/new_migration.sh "add document artifact path"'
  exit 1
fi

TIMESTAMP="$(date '+%Y%m%d%H%M%S')"
DESCRIPTION="$(printf '%s' "$*" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '_' | sed 's/^_*//;s/_*$//')"
FILE="migrations/V${TIMESTAMP}__${DESCRIPTION}.sql"

cat > "$FILE" <<SQL
-- ${FILE##*/}

-- Flyway manages the migration transaction.
-- Add SQL changes here.

SQL

echo "Created: $FILE"
