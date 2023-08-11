#!/bin/bash

set -e

taint_result=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME | { grep taint || true; })

if [ ! -z "$taint_result" ]; then
  echo "Deleting taint node group..."

  eksctl delete nodegroup taint-mng --cluster $EKS_CLUSTER_NAME --wait > /dev/null
fi