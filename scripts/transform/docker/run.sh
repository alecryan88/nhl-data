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
        --env-file .env 2>/dev/null || true \
        $IMAGE "$@"
else
    docker run --rm \
        --env-file .env 2>/dev/null || true \
        $IMAGE "$@"
fi

