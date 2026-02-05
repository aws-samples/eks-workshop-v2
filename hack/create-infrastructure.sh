#!/bin/bash

environment=$1

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

bash $SCRIPT_DIR/update-iam-role.sh $environment

sleep 5

cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_NAME}" &> /dev/null || cluster_exists=$?

if [ $cluster_exists -eq 0 ]; then
  echo "Cluster ${EKS_CLUSTER_NAME} already exists"
else
  echo "Creating cluster ${EKS_CLUSTER_NAME}"
  bash $SCRIPT_DIR/exec.sh "${environment}" 'cat /cluster/eksctl/cluster.yaml | envsubst | eksctl create cluster -f -'&
fi

auto_cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_AUTO_NAME}" &> /dev/null || auto_cluster_exists=$?

if [ $auto_cluster_exists -eq 0 ]; then
  echo "Auto mode cluster ${EKS_CLUSTER_AUTO_NAME} already exists"
else
  echo "Creating auto mode cluster ${EKS_CLUSTER_AUTO_NAME} with terraform"
  bash $SCRIPT_DIR/exec.sh "${environment}" 'cat /cluster/eksctl/cluster-auto.yaml | envsubst'
  bash $SCRIPT_DIR/exec.sh "${environment}" 'cat /cluster/eksctl/cluster-auto.yaml | envsubst | eksctl create cluster -f -'&
fi

wait