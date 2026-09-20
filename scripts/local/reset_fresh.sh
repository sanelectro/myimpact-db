#!/usr/bin/env bash
set -euo pipefail

# Destructive local reset:
# - Stops MyImpact DB containers
# - Deletes the PostgreSQL Docker volume
# - Recreates PostgreSQL
# - Re-applies Flyway migrations
#
# This creates a fresh database containing schema only.
# Demo/test data is NOT seeded automatically.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

if [[ ! -f "docker-compose.yml" ]]; then
  echo "ERROR: docker-compose.yml not found in ${ROOT_DIR}" >&2
  exit 1
fi

echo
echo "WARNING: This will DELETE the local MyImpact PostgreSQL data volume."
echo "This is intended for LOCAL DEVELOPMENT ONLY."
echo
read -r -p "Type RESET to continue: " confirmation

if [[ "${confirmation}" != "RESET" ]]; then
  echo "Reset cancelled."
  exit 0
fi

echo
echo "Stopping containers and removing local database volume..."
docker compose down -v --remove-orphans

echo
echo "Starting a fresh PostgreSQL instance..."
docker compose up -d postgres

echo
echo "Applying Flyway migrations..."
./scripts/db/migrate.sh

echo
echo "Checking migration state..."
./scripts/db/status.sh

echo
echo "Fresh local database is ready."
echo "Schema has been created; demo data has NOT been seeded."
echo
echo "To add demo data:"
echo "  ./scripts/demo/seed_demo_data.sh"
