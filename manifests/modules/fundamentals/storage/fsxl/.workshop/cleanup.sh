#!/bin/bash

set -e

logmessage "Deleting assets-images folder..."

# Delete local directory of image files
rm -rf ~/environment/assets-images/

check=$(helm list -n kube-system | grep aws-fsx-csi-driver || true)

logmessage "Scaling down assets deployment..."

kubectl scale -n assets --replicas=0 deployment/assets

if [ ! -z "$check" ]; then
  # logmessage "Deleting FSX Lustre CSI driver addon..."

  helm uninstall aws-fsx-csi-driver -n kube-system
fi

logmessage "Deleting PV and PVC that were created..."

# Delete PVC
kubectl delete pvc fsx-claim -n assets --ignore-not-found=true

# Delete PV
kubectl delete pv fsx-pv --ignore-not-found=true

