#!/bin/bash

set -e

EKS_CLUSTER_AUTO_NAME="eks-workshop-auto"

echo "Resetting $EKS_CLUSTER_AUTO_NAME cluster to clean state..."

# Update kubeconfig to point to auto-mode cluster
aws eks update-kubeconfig --name $EKS_CLUSTER_AUTO_NAME --alias eks-workshop-auto

# Delete any workshop-created resources
kubectl delete namespace other --ignore-not-found
kubectl delete pod load-generator --ignore-not-found

# Clean up KEDA resources if present
kubectl delete all --all -n keda --ignore-not-found 2>/dev/null || true
kubectl delete namespace keda --ignore-not-found

# Clean up any Ingress resources
kubectl delete ingress --all -A --ignore-not-found

echo "Cluster reset complete!"
