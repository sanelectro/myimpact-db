#!/usr/bin/env bash
set -euo pipefail

: "${FLYWAY_URL:=jdbc:postgresql://host.docker.internal:5556/myimpact}"
: "${FLYWAY_USER:=myimpact}"
: "${FLYWAY_IMAGE:=flyway/flyway:13.7.0}"

if [[ -z "${FLYWAY_PASSWORD:-}" ]]; then
  read -r -s -p "Database password: " FLYWAY_PASSWORD
  echo
fi

docker run --rm \
  -v "$(pwd)/migrations:/flyway/sql:ro" \
  "$FLYWAY_IMAGE" \
  -locations=filesystem:/flyway/sql \
  -url="$FLYWAY_URL" \
  -user="$FLYWAY_USER" \
  -password="$FLYWAY_PASSWORD" \
  migrate
