#!/bin/bash

environment=$1

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_NAME}" &> /dev/null || cluster_exists=$?

if [ $cluster_exists -eq 0 ]; then
  echo "Deleting cluster ${EKS_CLUSTER_NAME}"
  bash $SCRIPT_DIR/exec.sh "${environment}" 'cat /cluster/eksctl/cluster.yaml | envsubst | eksctl delete cluster --wait --force --disable-nodegroup-eviction --timeout 45m -f -'
else
  echo "Cluster ${EKS_CLUSTER_NAME} does not exist"
fi

aws iam delete-role-policy \
  --role-name ${EKS_CLUSTER_NAME}-ide-role \
  --policy-name labs > /dev/null || true

aws iam delete-role-policy \
  --role-name ${EKS_CLUSTER_NAME}-ide-role \
  --policy-name base > /dev/null || true

aws iam delete-role \
  --role-name ${EKS_CLUSTER_NAME}-ide-role > /dev/null || true