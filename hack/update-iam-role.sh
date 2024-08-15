#!/bin/bash

environment=$1

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

ROLE_CFN_TEMPLATE=$(mktemp)

cat $SCRIPT_DIR/../lab/iam/iam-role-cfn.yaml | Region=${AWS_REGION} Account=${ACCOUNT_ID} Env=${EKS_CLUSTER_NAME} envsubst | yq > $ROLE_CFN_TEMPLATE

aws cloudformation deploy \
    --stack-name ${EKS_CLUSTER_NAME}-ide-role \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --template-file $ROLE_CFN_TEMPLATE