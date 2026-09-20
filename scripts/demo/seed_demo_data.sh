#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="${SCRIPT_DIR}/seed_demo_data.sql"

CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:-myimpact-postgres}"
DB_USER="${POSTGRES_USER:-myimpact}"
DB_NAME="${POSTGRES_DB:-myimpact}"

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "ERROR: SQL file not found: ${SQL_FILE}" >&2
  exit 1
fi

echo "Seeding demo data into ${DB_NAME}..."

docker exec -i "${CONTAINER_NAME}"   psql -v ON_ERROR_STOP=1   -U "${DB_USER}"   -d "${DB_NAME}" < "${SQL_FILE}"

echo
echo "Demo data seeded successfully."
echo "  id:    demo-user"
echo "  name:  Demo User"
echo "  email: demo-user@abc.com"
echo "  role:  Lead Engineer"
