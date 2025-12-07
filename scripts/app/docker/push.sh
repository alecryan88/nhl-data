#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don’t ignore errors in pipelines


# Constants
source ./scripts/shared/ecr_base.sh

if [[ $ENV == "prod" ]]
then
    # pull the image and push to prod
    # This is used for the CD workflow because we don't want to build the image again.
    echo "Pulling CI image"
    docker pull $FULL_REPOSITORY_NAME:ci
    echo "Re-tagging for prod"
    docker tag $FULL_REPOSITORY_NAME:ci $FULL_REPOSITORY_NAME:$ENV
    echo "Pushing to prod image to ECR"
    docker push $FULL_REPOSITORY_NAME:$ENV


elif [[ $ENV == "ci" ]]
then
    echo "Pushing to ECR in CI environment"
    docker push $FULL_REPOSITORY_NAME:$GIT_SHA
    docker push $FULL_REPOSITORY_NAME:$ENV
fi