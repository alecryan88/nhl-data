#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don't ignore errors in pipelines

source ./scripts/shared/ecr_base.sh

if [[ $ENV == "dev" ]]
then
    # Tags image with the git sha, no main tag. This is used for quick development and testing.
    echo "Building the ingestion image in ${ENV} environment"
    docker build -t "${FULL_REPOSITORY_NAME}:${GIT_SHA}" -f ingestion/Dockerfile ./ingestion

elif [[ $ENV == "ci" ]]
then
    # Tags image with the git sha, and env tag. This is used for CI environment only.
    # We'll push this image to ECR in the push.sh script.
    echo "Building the ingestion image in ${ENV} environment"
    docker build -t "${FULL_REPOSITORY_NAME}:${GIT_SHA}" -t "${FULL_REPOSITORY_NAME}:${ENV}" -f ingestion/Dockerfile ./ingestion
fi

