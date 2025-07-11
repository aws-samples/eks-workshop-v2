# #!/bin/bash

# Anything user has created after prepare-environment

set -e

logmessage "Deleting assets-images folder..."

# Delete local directory of image files
rm -rf ~/environment/assets-images/

addon_exists=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-mountpoint-s3-csi-driver']" --output text)

logmessage "Scaling down ui deployment..."

# Scale down ui
kubectl scale -n ui --replicas=0 deployment/ui

logmessage "Deleting PV and PVC that were created..."

# Delete PVC
kubectl delete pvc s3-claim -n ui --ignore-not-found=true

# Delete PV
kubectl delete pv s3-pv --ignore-not-found=true

# Check if the S3 CSI driver addon exists
if [ ! -z "$addon_exists" ]; then
  # Delete if addon exists
  logmessage "Deleting S3 CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver
fi