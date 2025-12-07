#!/bin/bash

# Set variables specific to ECR

source ./scripts/shared/common.sh

# This is the ECR registry for the project.
ECR_REGISTRY=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# This is the full repository name for the project.
# It includes the environment name.
FULL_REPOSITORY_NAME=$ECR_REGISTRY/$PROJECT_NAME

export ECR_REGISTRY=$ECR_REGISTRY
export FULL_REPOSITORY_NAME=$FULL_REPOSITORY_NAME
export ECR_GIT_SHA_TAG=$FULL_REPOSITORY_NAME:$GIT_SHA
export ECR_ENV_TAG=$FULL_REPOSITORY_NAME:$ENV