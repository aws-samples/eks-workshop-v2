#!/bin/bash

set -e

taint_result=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME | { grep taint || true; })

if [ ! -z "$taint_result" ]; then
  echo "Deleting taint node group..."

  eksctl delete nodegroup taint-mng --cluster $EKS_CLUSTER_NAME --wait > /dev/null
fi

spot_nodegroup=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --query "nodegroups[? @ == 'managed-spot']" --output text)

if [ ! -z "$spot_nodegroup" ]; then
  echo "Deleting managed-spot node group..."

  aws eks delete-nodegroup --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --nodegroup-name managed-spot > /dev/null
  aws eks wait nodegroup-deleted --cluster-name $EKS_CLUSTER_NAME --nodegroup-name managed-spot > /dev/null
fi