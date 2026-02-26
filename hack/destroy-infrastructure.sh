#!/bin/bash

environment=$1
cluster=${2:-all}
echo "Destroying infrastructure for environment ${environment} and cluster ${cluster}"

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export USE_CURRENT_USER=1;
source $SCRIPT_DIR/lib/common-env.sh

cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_NAME}" &> /dev/null || cluster_exists=$?

if [ $cluster_exists -eq 0 ] && [[ "$cluster" == "standard" || "$cluster" == "all" ]]; then
  echo "Deleting cluster ${EKS_CLUSTER_NAME}"
  bash $SCRIPT_DIR/shell.sh "${environment}" 'delete-environment' || true
  bash $SCRIPT_DIR/exec.sh "${environment}" 'eksctl delete cluster --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --wait --force --disable-nodegroup-eviction --timeout 45m'&
else
  echo "Cluster ${EKS_CLUSTER_NAME} does not exist or skipped"
fi

export EKS_CLUSTER_AUTO_NAME="${EKS_CLUSTER_NAME}-auto"
auto_cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_AUTO_NAME}" &> /dev/null || auto_cluster_exists=$?

if [ $auto_cluster_exists -eq 0 ] && [[ "$cluster" == "auto" || "$cluster" == "all" ]]; then
  echo "Deleting auto mode cluster ${EKS_CLUSTER_AUTO_NAME}"
  #bash $SCRIPT_DIR/shell.sh "${environment}" 'delete-environment' || true # Needed ?
  bash $SCRIPT_DIR/exec.sh "${environment}" 'eksctl delete cluster --name ${EKS_CLUSTER_AUTO_NAME} --region ${AWS_REGION} --wait --force --disable-nodegroup-eviction --timeout 45m'
else
  echo "Auto mode cluster ${EKS_CLUSTER_AUTO_NAME} does not exist or skipped"
fi

wait

# Only delete ide-role if all clusters are deleted
if [ "$cluster" == "all" ]; then
  aws cloudformation delete-stack --stack-name ${EKS_CLUSTER_NAME}-ide-role || true
fi