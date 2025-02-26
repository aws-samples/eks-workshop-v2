# #!/bin/bash

# Anything user has created after prepare-environment

set -e

logmessage "Deleting assets-images folder..."

# Delete local directory of image files
rm -rf ~/environment/assets-images/

logmessage "Scaling down assets deployment..."

# Scale down assets
kubectl scale -n assets --replicas=0 deployment/assets

logmessage "Deleting PV and PVC that were created..."

# Delete PVC
kubectl delete pvc fsxz-fs-pvc -n assets --ignore-not-found=true
kubectl delete pvc fsxz-vol-pvc -n assets --ignore-not-found=true

# Delete PV
kubectl delete pv fsxz-fs-pv --ignore-not-found=true
kubectl delete pv fsxz-vol-pv --ignore-not-found=true

kubectl delete storageclass fsxz-fs-sc --ignore-not-found=true
kubectl delete storageclass fsxz-vol-sc --ignore-not-found=true

uninstall-helm-chart aws-fsx-openzfs-csi-driver kube-system