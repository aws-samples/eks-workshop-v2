#!/bin/bash

kubectl delete ingress dogbooth -n dogbooth --ignore-not-found
kubectl delete rayservice dogbooth -n dogbooth --ignore-not-found
kubectl delete ns dogbooth --ignore-not-found

helm uninstall jupyterhub -n jupyterhub
helm uninstall nginx-ingress
helm uninstall kuberay-operator

# Uninstall gpu-operator
GPU_OPERATOR_RELEASE_NAME=$(helm list -n gpu-operator -q)
helm uninstall $GPU_OPERATOR_RELEASE_NAME -n gpu-operator

delete-all-if-crd-exists nodepools.karpenter.sh
delete-all-if-crd-exists ec2nodeclasses.karpenter.k8s.aws

EXIT_CODE=0

timeout --foreground -s TERM 30 bash -c \
    'while [[ $(kubectl get nodes --selector=type=karpenter -o json | jq -r ".items | length") -gt 0 ]];\
    do sleep 5;\
    done' || EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  logmessage "Warning: Karpenter nodes did not clean up"
fi

uninstall-helm-chart karpenter karpenter
