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

IAM_POLICY=$(cat $SCRIPT_DIR/../lab/iam-policy.json | Region=${AWS_REGION} Account=${ACCOUNT_ID} Environment=${EKS_CLUSTER_NAME} envsubst)

aws iam put-role-policy \
  --role-name ${IDE_ROLE_NAME} \
  --policy-name default \
  --policy-document "${IAM_POLICY}" > /dev/null

bash $SCRIPT_DIR/exec.sh "${environment}" 'cat /cluster/eksctl/cluster.yaml | envsubst | eksctl create cluster -f -'

aws eks create-access-entry --cluster-name ${EKS_CLUSTER_NAME} --principal-arn ${IDE_ROLE_ARN}

aws eks associate-access-policy --cluster-name ${EKS_CLUSTER_NAME} --principal-arn ${IDE_ROLE_ARN} \
    --access-scope type=cluster --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy