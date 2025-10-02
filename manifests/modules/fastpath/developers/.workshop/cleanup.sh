#!/bin/bash

set -e

# Common
kubectl delete namespace ui --ignore-not-found
kubectl delete namespace catalog --ignore-not-found
kubectl delete namespace carts --ignore-not-found

# Autoscaling
kubectl delete pod load-generator --ignore-not-found

uninstall-helm-chart keda keda
kubectl delete ns keda --ignore-not-found

# Identity
POD_ASSOCIATION_ID=$(aws eks list-pod-identity-associations --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --service-account carts --namespace carts --output text --query 'associations[0].associationId')

if [ "$POD_ASSOCIATION_ID" != "None" ]; then
  logmessage "Deleting EKS Pod Identity Association..."
  
  aws eks delete-pod-identity-association --region $AWS_REGION --association-id $POD_ASSOCIATION_ID --cluster-name $EKS_CLUSTER_NAME

fi

pod_identity_check=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION --query "addons[? @ == 'eks-pod-identity-agent']" --output text)

if [ ! -z "$pod_identity_check" ]; then
  logmessage "Deleting EKS Pod Identity Agent addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent --region $AWS_REGION

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent --region $AWS_REGION
fi

# Storage
csi_check=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-efs-csi-driver']" --output text)

logmessage "Deleting EFS storage class..."

kubectl delete storageclass efs-sc --ignore-not-found

if [ ! -z "$csi_check" ]; then
  logmessage "Deleting EFS CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver
fi

# Ingress
uninstall-helm-chart external-dns external-dns

uninstall-helm-chart aws-load-balancer-controller kube-system