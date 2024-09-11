#!/bin/bash

kubectl delete ingress dogbooth -n dogbooth --ignore-not-found
kubectl delete rayservice dogbooth -n dogbooth --ignore-not-found
kubectl delete ns dogbooth --ignore-not-found

helm uninstall jupyterhub -n jupyterhub
helm uninstall nginx-ingress
helm uninstall kuberay-operator
kubectl delete ns jupyterhub

# Uninstall gpu-operator
GPU_OPERATOR_RELEASE_NAME=$(helm list -n gpu-operator -q)
helm uninstall $GPU_OPERATOR_RELEASE_NAME -n gpu-operator
kubectl delete ns gpu-operator