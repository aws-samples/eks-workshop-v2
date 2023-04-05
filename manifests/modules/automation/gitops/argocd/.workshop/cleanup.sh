#!/bin/bash

echo "Deleting ArgoCD application..."

argocd app delete argocd-demo -y > /dev/null || true

echo "Deleting ArgoCD demo namespace..."

kubectl delete namespace argocd-demo > /dev/null || true