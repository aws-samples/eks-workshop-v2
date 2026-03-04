#!/bin/bash

environment=$1
cluster=${2:-all}
echo "Creating infrastructure for environment ${environment} and cluster ${cluster}"

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

bash $SCRIPT_DIR/update-iam-role.sh $environment

sleep 5
export USE_CURRENT_USER=1 # We don't want to change the ARN in exec

cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_NAME}" &> /dev/null || cluster_exists=$?

if [ $cluster_exists -ne 0 ] && [[ "$cluster" == "standard" || "$cluster" == "all" ]]; then
  echo "Creating cluster ${EKS_CLUSTER_NAME}"
  bash $SCRIPT_DIR/exec.sh "${environment}" 'cat /cluster/eksctl/cluster.yaml /cluster/eksctl/access-entries.yaml | envsubst | eksctl create cluster -f -'&
else
  echo "Cluster ${EKS_CLUSTER_NAME} already exists"
fi

auto_cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_AUTO_NAME}" &> /dev/null || auto_cluster_exists=$?

if [ $auto_cluster_exists -ne 0 ] && [[ "$cluster" == "standard" || "$cluster" == "all" ]]; then
  echo "Creating auto mode cluster ${EKS_CLUSTER_AUTO_NAME}"
  bash $SCRIPT_DIR/exec.sh "${environment}" 'cat /cluster/eksctl/cluster-auto.yaml /cluster/eksctl/access-entries.yaml | envsubst | eksctl create cluster -f -'&
else
  echo "Auto mode cluster ${EKS_CLUSTER_AUTO_NAME} already exists"
fi

wait