#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd $SCRIPT_DIR/..

export ENABLE_INDEX=${ENABLE_INDEX:0}
export MANIFESTS_REF="$BRANCH"
export SHOW_NOTIFICATION=${SHOW_NOTIFICATION:0}

yarn install
yarn workspace website clear
yarn workspace website build

cd website

aws s3 sync build/ s3://${CONTENT_BUCKET} --delete

aws cloudfront create-invalidation --distribution-id ${CONTENT_CLOUDFRONT} --paths /\*