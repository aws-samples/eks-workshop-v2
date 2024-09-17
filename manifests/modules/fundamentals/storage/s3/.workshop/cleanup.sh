#!/bin/bash


# Ensure cleanup is all good before deploying!

set -e

addon_exists=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-mountpoint-s3-csi-driver']" --output text)

# Check if the bucket exists
bucket_exists=$(aws s3 ls "s3://$BUCKET_NAME" 2>&1 > /dev/null)

if [ $bucket_exists -eq 0 ]; then
    echo "The bucket $BUCKET_NAME exists"
    # Perform additional actions if the bucket exists

# Check if the IAM CSI Driver role exists
role_exists=$(aws iam get-role --role-name "$S3_CSI_ADDON_ROLE" > /dev/null 2>&1)

if [ $role_exists -eq 0 ]; then
    echo "The IAM role $S3_CSI_ADDON_ROLE exists"
    # Perform additional actions if the role exists

# Scale down assets
kubectl scale -n assets --replicas=0 deployment/assets

# Delete the S3 CSI driver addon
if [ ! -z "$addon_exists" ]; then
  logmessage "Deleting S3 CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver
fi