#!/bin/bash

echo "Deleting ENI configs..."

kubectl delete ENIConfig --all -A > /dev/null

echo "Resetting VPC CNI configuration..."

kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=false > /dev/null

custom_nodegroup=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --query "nodegroups[? @ == 'custom-networking']" --output text)

if [ ! -z "$custom_nodegroup" ]; then
  echo "Deleting custom networking node group..."

  aws eks delete-nodegroup --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking > /dev/null
  aws eks wait nodegroup-deleted --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking > /dev/null
fi
