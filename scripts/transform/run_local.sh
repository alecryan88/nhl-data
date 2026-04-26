#!/bin/bash
set -euo pipefail

COMMAND="${1:-run}"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GIT_SHA=$(git -C "$PROJECT_ROOT" rev-parse HEAD)
GIT_BRANCH=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD)

echo "Building transform image..."
docker build -t nhl-dbt-transform:local -f "$PROJECT_ROOT/transform/Dockerfile" "$PROJECT_ROOT"

echo "Running: dbt $COMMAND"
docker run --rm \
    --env-file "$PROJECT_ROOT/transform/.env" \
    -e DBT_PROFILES_DIR=/app \
    -e OPENLINEAGE__FACETS__SOURCE_CODE_LOCATION__VERSION="$GIT_SHA" \
    -e OPENLINEAGE__FACETS__SOURCE_CODE_LOCATION__BRANCH="$GIT_BRANCH" \
    ${OPENLINEAGE_PARENT_ID:+-e OPENLINEAGE_PARENT_ID="$OPENLINEAGE_PARENT_ID"} \
    nhl-dbt-transform:local "$COMMAND"
