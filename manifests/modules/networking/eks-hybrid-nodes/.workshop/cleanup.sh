#!/bin/bash

set -e

logmessage "Cleaning up EKS Hybrid Nodes Module"

kubectl delete -k ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kustomize --ignore-not-found=true

kubectl delete deployment nginx-deployment --ignore-not-found=true

delete-all-if-crd-exists clusterpolicies.kyverno.io

uninstall-helm-chart cilium cilium
uninstall-helm-chart kyverno kyverno

kubectl delete namespace cilium --ignore-not-found
kubectl delete namespace kyverno --ignore-not-found

kubectl delete nodes -l eks.amazonaws.com/compute-type=hybrid --ignore-not-found=true
