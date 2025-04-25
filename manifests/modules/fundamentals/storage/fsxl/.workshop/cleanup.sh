#!/bin/bash

set -e

check=$(helm list -n kube-system | grep aws-fsx-csi-driver || true)

kubectl scale -n assets --replicas=0 deployment/assets

if [ ! -z "$check" ]; then
  logmessage "Deleting FSX Lustre CSI driver addon..."

  helm uninstall aws-fsx-csi-driver -n kube-system
fi

# Delete PVC
kubectl delete pvc fsx-claim -n assets --ignore-not-found=true

# Delete PV
kubectl delete pv fsx-pv --ignore-not-found=true

logmessage "Deleting PV and PVC that were created..."