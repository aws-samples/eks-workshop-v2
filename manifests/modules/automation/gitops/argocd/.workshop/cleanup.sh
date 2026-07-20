#!/bin/bash

set -e

logmessage "Deleting ArgoCD applications..."

kubectl patch applications.argoproj.io -A --all \
  --type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true

delete-all-and-wait-if-crd-exists applications.argoproj.io

rm -rf ~/environment/argocd

kubectl delete namespace argocd --ignore-not-found=true

kubectl delete namespace ui --ignore-not-found=true

kubectl delete namespace -l app.kubernetes.io/created-by=eks-workshop
