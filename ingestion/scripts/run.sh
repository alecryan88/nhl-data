#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don't ignore errors in pipelines

HANDLER="${1:?Usage: $0 <handler> (e.g. nhl_api_s3.lambda_handler)}"
shift

# Run build script
source ./scripts/ingestion/docker/build.sh

echo "ENV: $ENV"
echo "Handler: $HANDLER"

IMAGE="${FULL_REPOSITORY_NAME}:${GIT_SHA}"

# In dev, we mount only source files for hot reloading (not the whole dir, which would overwrite deps)
if [[ $ENV == "dev" ]]
then
    docker run --env-file .env -p 9000:8080 \
        -v $(pwd)/ingestion/lib:/var/task/lib \
        -v $(pwd)/ingestion/nhl_api_s3.py:/var/task/nhl_api_s3.py \
        -v $(pwd)/ingestion/nhl_api_supabase.py:/var/task/nhl_api_supabase.py \
        $IMAGE "$HANDLER" "$@"
elif [[ $ENV == "prod" ]]
then
    PROD_IMAGE="${FULL_REPOSITORY_NAME}:prod"
    echo "Pulling ${PROD_IMAGE}"
    docker pull $PROD_IMAGE
    docker run --env-file .env -p 9000:8080 $PROD_IMAGE "$HANDLER" "$@"
else
    docker run --env-file .env -p 9000:8080 $IMAGE "$HANDLER" "$@"
fi
