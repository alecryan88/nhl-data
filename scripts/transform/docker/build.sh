#!/bin/bash
set -euo pipefail 
# e: exit on any error
# u: treat unset variables as errors
# o pipefail: don't ignore errors in pipelines

source ./scripts/shared/common.sh

TRANSFORM_TAG="nhl-dbt-transform"

echo "Building the dbt transform image in ${ENV} environment"
docker build -t "${TRANSFORM_TAG}:${GIT_SHA}" -t "${TRANSFORM_TAG}:latest" -f transform/Dockerfile ./transform

export TRANSFORM_TAG=$TRANSFORM_TAG

