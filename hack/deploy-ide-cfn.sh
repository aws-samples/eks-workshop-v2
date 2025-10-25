#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

outfile=$(mktemp)

bash $SCRIPT_DIR/build-ide-cfn.sh $outfile

aws cloudformation deploy --stack-name "$EKS_CLUSTER_NAME-ide" \
  --capabilities CAPABILITY_NAMED_IAM --disable-rollback --template-file $outfile