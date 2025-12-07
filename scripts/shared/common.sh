#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don’t ignore errors in pipelines


# Set variables shared amongst ECR and CloudFormation

# If ENVIRONMENT is unset or empty, default to "dev"
ENV="${ENV:-dev}"

# Constants
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=us-east-1
GIT_SHA=$(git rev-parse HEAD)
PROJECT_NAME=nhl-data-pipeline

export GIT_SHA=$GIT_SHA
export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
export AWS_REGION=$AWS_REGION
export ENV=$ENV