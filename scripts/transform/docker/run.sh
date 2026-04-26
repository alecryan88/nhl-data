#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don't ignore errors in pipelines

# Run build script
source ./scripts/transform/docker/build.sh

echo "ENV: $ENV"

IMAGE="${TRANSFORM_TAG}:${GIT_SHA}"
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Pass all arguments to dbt (e.g., run, test, build, etc.)
# Mount the transform directory for development
if [[ $ENV == "dev" ]]
then
    docker run --rm \
        -v $(pwd)/transform:/app \
        -v $(pwd)/lineage:/app/lineage \
        -e PYTHONPATH=/app/lineage \
        -v /app/.venv \
        --env-file transform/.env \
        -e DBT_PROFILES_DIR=/app \
        -e OPENLINEAGE__FACETS__SOURCE_CODE_LOCATION__VERSION="$GIT_SHA" \
        -e OPENLINEAGE__FACETS__SOURCE_CODE_LOCATION__BRANCH="$GIT_BRANCH" \
        $IMAGE "$@"
else
    docker run --rm \
        --env-file transform/.env \
        -e DBT_PROFILES_DIR=/app \
        -e OPENLINEAGE__FACETS__SOURCE_CODE_LOCATION__VERSION="$GIT_SHA" \
        -e OPENLINEAGE__FACETS__SOURCE_CODE_LOCATION__BRANCH="$GIT_BRANCH" \
        $IMAGE "$@"
fi

