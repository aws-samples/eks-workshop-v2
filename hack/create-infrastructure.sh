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
  bash $SCRIPT_DIR/exec.sh "${environment}" 'cat /cluster/eksctl/cluster.yaml | envsubst | eksctl create cluster -f -'
fi

export EKS_AUTO_CLUSTER_NAME="${EKS_CLUSTER_NAME}-auto"
auto_cluster_exists=0
aws eks describe-cluster --name "${EKS_AUTO_CLUSTER_NAME}" &> /dev/null || auto_cluster_exists=$?

if [ $auto_cluster_exists -eq 0 ]; then
  echo "Auto mode cluster ${EKS_AUTO_CLUSTER_NAME} already exists"
else
  echo "Creating auto mode cluster ${EKS_AUTO_CLUSTER_NAME} with terraform"
  cd $SCRIPT_DIR/../cluster/terraform-auto
  terraform init
  terraform apply -auto-approve -var="auto_cluster_name=${EKS_AUTO_CLUSTER_NAME}"
fi