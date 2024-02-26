#!/bin/bash

set -e

logmessage "Deleting EFS storage class..."

kubectl delete storageclass efs-sc --ignore-not-found

check=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-efs-csi-driver']" --output text)

if [ ! -z "$check" ]; then
  logmessage "Deleting EFS CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver
fi