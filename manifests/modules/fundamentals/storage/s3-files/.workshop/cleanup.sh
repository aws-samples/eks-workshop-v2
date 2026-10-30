#!/bin/bash

set -e

check=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-efs-csi-driver']" --output text)

kubectl delete namespace ui --ignore-not-found

logmessage "Deleting S3 Files persistent volume and storage class..."

# The PersistentVolume uses a Retain reclaim policy, so it is not removed when
# the namespace (and its PersistentVolumeClaim) is deleted. Remove it explicitly.
kubectl delete pv s3-files-pv --ignore-not-found

kubectl delete storageclass s3-files-sc --ignore-not-found

if [ ! -z "$check" ]; then
  logmessage "Deleting EFS CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver
fi
