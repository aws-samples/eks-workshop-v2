#!/bin/bash


# Ensure cleanup is all good before deploying!

set -e

check=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-mountpoint-s3-csi-driver']" --output text)

kubectl delete storageclass efs-sc --ignore-not-found

# Scale down assets
kubectl scale -n assets --replicas=0 deployment/assets

# Delete the S3 CSI driver addon
if [ ! -z "$check" ]; then
  logmessage "Deleting S3 CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver
fi