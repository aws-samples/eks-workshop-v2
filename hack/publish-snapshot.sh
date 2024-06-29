#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd $SCRIPT_DIR/../website

export MANIFESTS_REF="snapshot-$SNAPSHOT"
export BASE_URL="$SNAPSHOT"

npm install
npm run clear
npm run build

aws s3 cp --recursive build/ s3://${SNAPSHOT_BUCKET}/${SHAPSHOT}

aws cloudfront create-invalidation --distribution-id ${SNAPSHOT_CLOUDFRONT} --paths /${SNAPSHOT}\*