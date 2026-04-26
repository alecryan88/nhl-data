#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don't ignore errors in pipelines

# Run build script
source ./scripts/transform/docker/build.sh

echo "ENV: $ENV"

IMAGE="${TRANSFORM_TAG}:${GIT_SHA}"

# Pass all arguments to dbt (e.g., run, test, build, etc.)
# Mount the transform directory for development
if [[ $ENV == "dev" ]]
then
    docker run --rm \
        -v $(pwd)/transform:/app \
        -v /app/.venv \
        --env-file transform/.env \
        -e DBT_PROFILES_DIR=/app \
        $IMAGE "$@"
else
    docker run --rm \
        --env-file transform/.env \
        -e DBT_PROFILES_DIR=/app \
        $IMAGE "$@"
fi

