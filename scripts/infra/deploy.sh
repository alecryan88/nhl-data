#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don't ignore errors in pipelines

source ./scripts/shared/common.sh

# Check if --ecr-only flag is passed (for initial deployment)
DEPLOY_LAMBDA="true"
if [[ "${1:-}" == "--ecr-only" ]]; then
    DEPLOY_LAMBDA="false"
    echo "Deploying ECR repository only for ${PROJECT_NAME}"
else
    echo "Deploying resources for ${PROJECT_NAME} with image tag ${GIT_SHA}"
fi

aws cloudformation deploy \
    --template-file ${PWD}/infra/cloudformation/resources.yml \
    --stack-name ${PROJECT_NAME} \
    --parameter-overrides \
        ProjectName=${PROJECT_NAME} \
        ImageTag=${GIT_SHA} \
        DeployLambda=${DEPLOY_LAMBDA} \
    --capabilities CAPABILITY_NAMED_IAM