#!/bin/bash

set -e

echo "Cleaning up developer essentials resources..."

# Delete load generator if running
kubectl delete pod load-generator --ignore-not-found

# Delete ingress resources
kubectl delete ingress --all -A --ignore-not-found
kubectl delete ingressclass eks-auto-alb --ignore-not-found

# Delete KEDA ScaledObjects and HPA
kubectl delete scaledobject --all -n ui --ignore-not-found 2>/dev/null || true
kubectl delete hpa --all -n ui --ignore-not-found 2>/dev/null || true

# Delete EBS storage class and modified StatefulSets + PVCs
kubectl delete statefulset -l app.kubernetes.io/created-by=eks-workshop -A --ignore-not-found
kubectl delete pvc --all -A --ignore-not-found
kubectl delete storageclass ebs-sc --ignore-not-found

# Delete pod identity associations for carts
for assoc in $(aws eks list-pod-identity-associations --cluster-name ${EKS_CLUSTER_AUTO_NAME:-eks-workshop-auto} --namespace carts --query 'associations[].associationId' --output text 2>/dev/null); do
  aws eks delete-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME:-eks-workshop-auto} --association-id $assoc 2>/dev/null || true
done

# Delete pod identity associations for keda (created by install-keda.md)
for assoc in $(aws eks list-pod-identity-associations --cluster-name ${EKS_CLUSTER_AUTO_NAME:-eks-workshop-auto} --namespace keda --query 'associations[].associationId' --output text 2>/dev/null); do
  aws eks delete-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME:-eks-workshop-auto} --association-id $assoc 2>/dev/null || true
done

# Delete network policies
kubectl delete networkpolicy --all -A --ignore-not-found 2>/dev/null || true

echo "Cleanup complete!"
