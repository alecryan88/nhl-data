#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don't ignore errors in pipelines

HANDLER="${1:?Usage: $0 <handler> (e.g. ingestion.producer.lambda_handler)}"
shift

# Run build script
source ./scripts/ingestion/docker/build.sh

echo "ENV: $ENV"
echo "Handler: $HANDLER"

# In dev, we mount the extract directory to the container for hot reloading
if [[ $ENV == "dev" ]]
then
    docker run --env-file .env -p 9000:8080 -v $(pwd)/ingestion:/var/task/ingestion $ECR_GIT_SHA_TAG "$HANDLER" "$@"
elif [[ $ENV == "prod" ]]
then
    echo "Pulling ${PROD_TAG}"
    docker pull $PROD_TAG
    docker run --env-file .env -p 9000:8080 $ECR_GIT_SHA_TAG "$HANDLER" "$@"
else
    docker run --env-file .env -p 9000:8080 $ECR_GIT_SHA_TAG "$HANDLER" "$@"
fi
