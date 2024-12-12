#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd $SCRIPT_DIR/..

export MANIFESTS_REF="$BRANCH"
export SNAPSHOT="${BRANCH#snapshot-}"
export BASE_URL="$SNAPSHOT"
export LAB_TIMES_ENABLED='true'

yarn install
yarn workspace website clear
yarn workspace website build

cd website

aws s3 cp --recursive build/ s3://${SNAPSHOT_BUCKET}/${SNAPSHOT}

aws cloudfront create-invalidation --distribution-id ${SNAPSHOT_CLOUDFRONT} --paths /${SNAPSHOT}\*