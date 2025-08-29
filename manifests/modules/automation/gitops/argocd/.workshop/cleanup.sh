#!/bin/bash

set -e

logmessage "Deleting ArgoCD applications..."

delete-all-and-wait-if-crd-exists applications.argoproj.io

rm -rf ~/environment/argocd

uninstall-helm-chart argocd argocd

kubectl delete namespace argocd --ignore-not-found=true

logmessage "Uninstalling Gitea"

uninstall-helm-chart gitea gitea

kubectl delete namespace gitea --ignore-not-found=true