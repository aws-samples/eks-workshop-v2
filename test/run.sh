#!/bin/bash

set -e

if [ -z "$EKS_CLUSTER_NAME" ]; then
  echo "Error: Must provide EKS_CLUSTER_NAME"
  exit 1
fi

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region ca-central-1

kubectl get nodes &> /dev/null

wtf "$@" /content 