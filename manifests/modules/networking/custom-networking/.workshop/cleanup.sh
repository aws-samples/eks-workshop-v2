#!/bin/bash

set -e

logmessage "WARNING! This lab takes additional time to clean up to ensure workshop stability, please be patient"

logmessage "Deleting ENI configs..."

kubectl delete ENIConfig --all -A

sleep 10

logmessage "Resetting VPC CNI configuration..."

kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=false

sleep 10

kubectl delete namespace checkout

logmessage "Terminating EKS worker nodes..."

INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups --filters "Name=tag:eks:nodegroup-name,Values=$EKS_DEFAULT_MNG_NAME" "Name=tag:eks:cluster-name,Values=$EKS_CLUSTER_NAME" --query 'AutoScalingGroups[0].Instances[].InstanceId' --output text)

for INSTANCE_ID in $INSTANCE_IDS
do
  aws ec2 terminate-instances --instance-ids $INSTANCE_ID
done

custom_nodegroup=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --query "nodegroups[? @ == 'custom-networking']" --output text)

if [ ! -z "$custom_nodegroup" ]; then
  logmessage "Deleting custom networking node group..."

  aws eks delete-nodegroup --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
  aws eks wait nodegroup-deleted --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
fi

sleep 30

kubectl wait --for=condition=Ready --timeout=15m pods -l app.kubernetes.io/created-by=eks-workshop -A