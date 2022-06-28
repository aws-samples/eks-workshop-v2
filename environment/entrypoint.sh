#!/bin/bash

set -e

if [ ! -z "$EKS_CLUSTER_NAME" ]; then
  aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
fi

bash -l