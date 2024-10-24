#!/bin/bash

aws eks update-kubeconfig --name eks-workshop

if kubectl get deployment efs-app -n default > /dev/null 2>&1; then
    kubectl delete deployment efs-app -n default
else
    echo "Deployment efs-app does not exist."
fi

if kubectl get pvc efs-claim -n default > /dev/null 2>&1; then
    kubectl delete pvc efs-claim -n default
else
    echo "PVC efs-claim does not exist."
fi
PV_NAME=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.name=="efs-claim")].metadata.name}')
if [ -n "$PV_NAME" ]; then
    kubectl delete pv "$PV_NAME"
else
    echo "No PV associated with efs-claim."
fi

if kubectl get storageclass efs-sc > /dev/null 2>&1; then
    kubectl delete storageclass efs-sc
else
    echo "Storage class efs-sc does not exist."
fi
