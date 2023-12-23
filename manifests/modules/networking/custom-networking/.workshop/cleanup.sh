#!/bin/bash

set -e

logmessage "Deleting ENI configs..."

kubectl delete ENIConfig --all -A

sleep 10

logmessage "Resetting VPC CNI configuration..."

kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=false

sleep 10

custom_nodegroup=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --query "nodegroups[? @ == 'custom-networking']" --output text)

if [ ! -z "$custom_nodegroup" ]; then
  logmessage "Deleting custom networking node group..."

  aws eks delete-nodegroup --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
  aws eks wait nodegroup-deleted --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
fi
