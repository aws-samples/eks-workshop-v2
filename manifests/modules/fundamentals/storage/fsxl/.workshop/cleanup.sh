#!/bin/bash

set -e

check=$(helm list -n kube-system | grep aws-fsx-csi-driver || true)

kubectl scale -n assets --replicas=0 deployment/assets

logmessage "Deleting FSX Lustre storage class..."

kubectl delete storageclass fsx-sc --ignore-not-found

if [ ! -z "$check" ]; then
  logmessage "Deleting FSX Lustre CSI driver addon..."

  helm uninstall aws-fsx-csi-driver -n kube-system
fi

# Delete PVC
kubectl delete pvc fsx-claim -n assets --ignore-not-found=true

logmessage "Deleting PV and PVC that were created..."