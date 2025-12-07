#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don’t ignore errors in pipelines

# Run build script
source ./scripts/app/docker/build.sh

echo "ENV: $ENV"
echo "PWD: $PWD"
echo "ECR_GIT_SHA_TAG: $ECR_GIT_SHA_TAG"
echo "ECR_ENV_TAG: $ECR_ENV_TAG"

# In dev, we mount the extract directory to the container for hot reloading
if [[ $ENV == "dev" ]]
then
    docker run --env-file .env -p 9000:8080 -v $(pwd)/app:/var/task/app $ECR_GIT_SHA_TAG "$@"
elif [[ $ENV == "prod" ]]
then
    echo "Running in ${ENV} environment"
    echo "Pulling ${PROD_TAG}"
    docker pull $PROD_TAG
    docker run --env-file .env $ECR_GIT_SHA_TAG "$@"
else
    echo "Running in ${ENV} environment"
    docker run --env-file .env $ECR_GIT_SHA_TAG "$@"
fi