#!/bin/bash

set -e

POD_ASSOCIATION_ID=$(aws eks list-pod-identity-associations --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --service-account carts --namespace carts --output text --query 'associations[0].associationId')

if [ ! -z "$POD_ASSOCIATION_ID" ]; then
  logmessage "Deleting EKS Pod Identity Association..."
  
  aws eks delete-pod-identity-association --region $AWS_REGION --association-id $POD_ASSOCIATION_ID --cluster-name $EKS_CLUSTER_NAME

fi
