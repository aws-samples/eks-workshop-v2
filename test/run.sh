#!/bin/bash

set -e

if [ -z "$EKS_CLUSTER_NAME" ]; then
  echo "Error: Must provide EKS_CLUSTER_NAME"
  exit 1
fi

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME

node /app/dist/cli.js test "$@" /content 