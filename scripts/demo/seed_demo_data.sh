#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="${SCRIPT_DIR}/seed_demo_data.sql"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
AUTH_DIR="${WORKSPACE_ROOT}/myimpact-api"
AUTH_PYTHON="${MYIMPACT_AUTH_PYTHON:-${AUTH_DIR}/.venv/bin/python}"

CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:-myimpact-postgres}"
DB_USER="${POSTGRES_USER:-myimpact}"
DB_NAME="${POSTGRES_DB:-myimpact}"

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "ERROR: SQL file not found: ${SQL_FILE}" >&2
  exit 1
fi
DEMO_USER_PASSWORD="${DEMO_USER_PASSWORD:-}"
if [[ ${#DEMO_USER_PASSWORD} -lt 12 ]]; then
  echo "ERROR: Set DEMO_USER_PASSWORD to a local demo password of at least 12 characters." >&2
  exit 1
fi
if [[ ! -x "${AUTH_PYTHON}" ]]; then
  echo "ERROR: Authentication Python environment not found: ${AUTH_PYTHON}" >&2
  echo "Set MYIMPACT_AUTH_PYTHON to the authentication service Python executable." >&2
  exit 1
fi

echo "Seeding demo data into ${DB_NAME}..."

(
  cd "${AUTH_DIR}"
  DEMO_USER_PASSWORD="${DEMO_USER_PASSWORD}" "${AUTH_PYTHON}" "${SCRIPT_DIR}/seed_demo_accounts.py" --preflight-only
)

docker exec -i "${CONTAINER_NAME}"   psql -v ON_ERROR_STOP=1   -U "${DB_USER}"   -d "${DB_NAME}" < "${SQL_FILE}"

(
  cd "${AUTH_DIR}"
  DEMO_USER_PASSWORD="${DEMO_USER_PASSWORD}" "${AUTH_PYTHON}" "${SCRIPT_DIR}/seed_demo_accounts.py"
)

echo
echo "Demo data seeded successfully."
echo "  Ten demo accounts (nine employees and one MyImpact admin) share DEMO_USER_PASSWORD."
echo "  See myimpact-ai/demo-data/demo_personas.json for the employee account list."
echo "  MyImpact platform admin: myimpact-admin@example.com"
