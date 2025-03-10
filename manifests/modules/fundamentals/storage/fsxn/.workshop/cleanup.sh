#!/bin/bash

set -e

check=$(helm list --deployed -n trident -q)
kubectl scale -n assets --replicas=0 deployment/assets

logmessage "Deleting FSxN PVC..."
kubectl delete pvc fsxn-nfs-claim -n assets --ignore-not-found
logmessage "Deleting FSxN storage class..."
kubectl delete storageclass fsxn-sc-nfs --ignore-not-found
logmessage "Deleting FSxN backend config..."
kubectl delete tbc backend-tbc-ontap-nas -n trident --ignore-not-found

if [ ! -z "$check" ]; then
  logmessage "Deleting FSxN CSI driver..."

  helm uninstall $check -n trident
fi