### WHAT AM I MISSING FROM HERE???????

# #!/bin/bash

# Anything user has created after prepare-environment

set -e

logmessage "Deleting assets-images folder..."

# Delete local directory of image files
rm -rf ~/environment/assets-images/

addon_exists=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-fsx-openzfs-csi-driver']" --output text)

logmessage "Scaling down assets deployment..."

# Scale down assets
kubectl scale -n assets --replicas=0 deployment/assets

# Check if the FSxZ CSI driver addon exists
if [ ! -z "$addon_exists" ]; then
  # Delete if addon exists
  logmessage "Deleting FSxZ CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-fsx-openzfs-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-fsx-openzfs-csi-driver
fi

logmessage "Deleting PV and PVC that were created..."

# Delete PVC
kubectl delete pvc fsxz-fs-pvc -n assets --ignore-not-found=true
kubectl delete pvc fsxz-vol-pvc -n assets --ignore-not-found=true

# Delete PV
kubectl delete pv fsxz-fs-pv --ignore-not-found=true
kubectl delete pv fsxz-vol-pv --ignore-not-found=true