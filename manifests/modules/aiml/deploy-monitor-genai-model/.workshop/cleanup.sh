#!/bin/bash

kubectl delete ns dogbooth --ignore-not-found

uninstall-helm-chart jupyterhub jupyterhub
uninstall-helm-chart nginx-ingress default
uninstall-helm-chart kuberay-operator kuberay

kubectl delete ns jupyterhub --ignore-not-found

# Uninstall gpu-operator
uninstall-helm-chart gpu-operator gpu-operator

kubectl delete ns gpu-operator --ignore-not-found