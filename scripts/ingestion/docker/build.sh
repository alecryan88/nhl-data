#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don’t ignore errors in pipelines

source ./scripts/shared/ecr_base.sh

if [[ $ENV == "dev" ]]
then
    # Tags image with the git sha, no main tag. This is used for quick development and testing.
    echo "Building the image in ${ENV} environment"
    docker build -t $ECR_GIT_SHA_TAG -f Dockerfile .

elif [[ $ENV == "ci" ]]
then
    # Tags image with the git sha, and env tag. This is used for CI environment only.
    # We'll push this image to ECR in the push.sh script.
    echo "Building the image in ${ENV} environment"
    docker build -t $ECR_GIT_SHA_TAG -t $ECR_ENV_TAG -f Dockerfile .
fi

