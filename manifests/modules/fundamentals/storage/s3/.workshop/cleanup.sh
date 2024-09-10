#!/bin/bash


# Ensure cleanup is all good before deploying!

# Delete addon
eksctl delete addon --cluster $EKS_CLUSTER_NAME --name aws-mountpoint-s3-csi-driver --preserve

set -e

check=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-efs-csi-driver']" --output text)

kubectl scale -n assets --replicas=0 deployment/assets

logmessage "Deleting EFS storage class..."

kubectl delete storageclass efs-sc --ignore-not-found

if [ ! -z "$check" ]; then
  logmessage "Deleting EFS CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver
fi