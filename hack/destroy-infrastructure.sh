#!/bin/bash

environment=$1

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

#aws iam delete-role-policy \
#  --role-name ${EKS_CLUSTER_NAME}-ide-role \
#  --policy-name default > /dev/null
#
#aws iam delete-role \
#  --role-name ${EKS_CLUSTER_NAME}-ide-role > /dev/null

bash $SCRIPT_DIR/exec.sh "${environment}" 'cat /cluster/eksctl/cluster.yaml | envsubst | eksctl delete cluster --wait --force --disable-nodegroup-eviction --timeout 45m -f -'

