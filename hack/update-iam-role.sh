#!/bin/bash

environment=$1

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

outfile=$(mktemp)

cd lab

export Env="${EKS_CLUSTER_NAME}"

cat iam/iam-role-cfn.yaml | yq '(.. | select(has("file"))) |= (load(.file))' | envsubst '$Env' > $outfile

aws cloudformation deploy \
    --stack-name ${EKS_CLUSTER_NAME}-ide-role \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --template-file $outfile \
    --region $AWS_REGION