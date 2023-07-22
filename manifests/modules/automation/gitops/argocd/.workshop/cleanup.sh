#!/bin/bash

echo "Deleting ArgoCD applications..."

delete-all-if-crd-exists applications.argoproj.io

rm -rf ~/environment/argocd