#!/bin/bash

environment=$1

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

TRUST_POLICY=$(
cat <<HEREDOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::$ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
HEREDOC
)

aws iam create-role \
  --role-name ${IDE_ROLE_NAME} \
  --assume-role-policy-document "${TRUST_POLICY}" > /dev/null

BASE_IAM_POLICY=$(cat $SCRIPT_DIR/../lab/iam-policy-base.json | Region=${AWS_REGION} Account=${ACCOUNT_ID} Environment=${EKS_CLUSTER_NAME} envsubst)

aws iam put-role-policy \
  --role-name ${IDE_ROLE_NAME} \
  --policy-name base \
  --policy-document "${BASE_IAM_POLICY}" > /dev/null

LABS_IAM_POLICY=$(cat $SCRIPT_DIR/../lab/iam-policy-labs.json | Region=${AWS_REGION} Account=${ACCOUNT_ID} Environment=${EKS_CLUSTER_NAME} envsubst)

aws iam put-role-policy \
  --role-name ${IDE_ROLE_NAME} \
  --policy-name labs \
  --policy-document "${LABS_IAM_POLICY}" > /dev/null