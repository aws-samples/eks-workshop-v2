#!/bin/bash

set -e

check=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-ebs-csi-driver']" --output text)

kubectl delete namespace catalog --wait --ignore-not-found

if [ ! -z "$check" ]; then
  logmessage "Deleting EBS CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-ebs-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-ebs-csi-driver
fi