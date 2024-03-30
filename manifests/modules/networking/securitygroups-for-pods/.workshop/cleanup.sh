#!/bin/bash

set -e

logmessage "Deleting Security Group policies..."

kubectl delete SecurityGroupPolicy --all -A

sleep 10

# Clear the catalog pods so the SG can be deleted
kubectl rollout restart -n catalog deployment/catalog

logmessage "Terminating EKS worker nodes..."

INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups --filters "Name=tag:eks:nodegroup-name,Values=$EKS_DEFAULT_MNG_NAME" "Name=tag:eks:cluster-name,Values=$EKS_CLUSTER_NAME" --query 'AutoScalingGroups[0].Instances[].InstanceId' --output text)

for INSTANCE_ID in $INSTANCE_IDS
do
  aws ec2 terminate-instances --instance-ids $INSTANCE_ID
done

sleep 60