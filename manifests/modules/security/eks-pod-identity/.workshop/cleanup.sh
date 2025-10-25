#!/bin/bash

set -e

POD_ASSOCIATION_ID=$(aws eks list-pod-identity-associations --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --service-account carts --namespace carts --output text --query 'associations[0].associationId')

if [ "$POD_ASSOCIATION_ID" != "None" ]; then
  logmessage "Deleting EKS Pod Identity Association..."
  
  aws eks delete-pod-identity-association --region $AWS_REGION --association-id $POD_ASSOCIATION_ID --cluster-name $EKS_CLUSTER_NAME

fi

check=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION --query "addons[? @ == 'eks-pod-identity-agent']" --output text)

if [ ! -z "$check" ]; then
  logmessage "Deleting EKS Pod Identity Agent addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent --region $AWS_REGION

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent --region $AWS_REGION
fi
