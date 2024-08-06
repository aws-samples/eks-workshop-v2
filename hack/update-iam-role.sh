#!/bin/bash

environment=$1

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

IAM_POLICY=$(cat $SCRIPT_DIR/../lab/iam-policy.json | Region=${AWS_REGION} Account=${ACCOUNT_ID} Environment=${EKS_CLUSTER_NAME} envsubst)

aws iam put-role-policy \
  --role-name ${IDE_ROLE_NAME} \
  --policy-name default \
  --policy-document "${IAM_POLICY}" > /dev/null