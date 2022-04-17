#!/bin/bash

set -e

source ~/.bashrc

if [ -z "$EKS_CLUSTER_NAME" ]; then
  echo "Error: Must provide EKS_CLUSTER_NAME"
  exit 1
fi

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME

kubectl get nodes &> /dev/null

wtf "$@" /content 