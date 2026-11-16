#!/bin/bash

environment=$1
cluster=${2:-all}
export USE_CURRENT_USER=${USE_CURRENT_USER:-1} # We don't want to change the ARN in exec
echo "Creating infrastructure for environment ${environment} and cluster ${cluster}"

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

bash $SCRIPT_DIR/update-iam-role.sh $environment

sleep 5

pids=()

cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_NAME}" &> /dev/null || cluster_exists=$?

# The cluster creator already gets cluster admin from
# bootstrapClusterCreatorAdminPermissions. Adding a second access entry for the
# same principal fails, so skip access-entries.yaml when it names the caller
# (Workshop Studio sets RESOURCE_CODEBUILD_ROLE_ARN to the build role).
caller_role_arn=$(aws sts get-caller-identity --query Arn --output text | sed -E 's#^arn:([^:]+):sts::([0-9]+):assumed-role/([^/]+)/.*#arn:\1:iam::\2:role/\3#')
access_entries="/cluster/eksctl/access-entries.yaml"
if [ "${RESOURCE_CODEBUILD_ROLE_ARN:-}" = "$caller_role_arn" ]; then
  echo "Access entry principal is the cluster creator, skipping access-entries.yaml"
  access_entries=""
fi

if [ $cluster_exists -ne 0 ] && [[ "$cluster" == "standard" || "$cluster" == "all" ]]; then
  echo "Creating cluster ${EKS_CLUSTER_NAME}"
  # Always create the cluster as the caller: eksctl creates its own IAM roles,
  # which the IDE role is not allowed to create.
  USE_CURRENT_USER=1 bash $SCRIPT_DIR/exec.sh "${environment}" "cat /cluster/eksctl/cluster.yaml ${access_entries} | envsubst | eksctl create cluster -f -" &
  pids+=($!)
else
  echo "Cluster ${EKS_CLUSTER_NAME} already exists"
fi

auto_cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_AUTO_NAME}" &> /dev/null || auto_cluster_exists=$?

if [ $auto_cluster_exists -ne 0 ] && [[ "$cluster" == "auto" || "$cluster" == "all" ]]; then
  echo "Creating auto mode cluster ${EKS_CLUSTER_AUTO_NAME}"
  USE_CURRENT_USER=1 bash $SCRIPT_DIR/exec.sh "${environment}" "cat /cluster/eksctl/cluster-auto.yaml ${access_entries} | envsubst | eksctl create cluster -f -" &
  pids+=($!)
else
  echo "Auto mode cluster ${EKS_CLUSTER_AUTO_NAME} already exists"
fi

if [ ${#pids[@]} -gt 0 ]; then
  for pid in "${pids[@]}"; do
    wait "$pid" || exit 1
  done
fi