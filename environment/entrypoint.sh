#!/bin/bash

set -e

if [ ! -z "$EKS_CLUSTER_NAME" ]; then
  aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
fi

# TODO: Move to .bashrc or similar
export AWS_PAGER=""

if [ $# -eq 0 ]
  then
    bash -l
else
  bash -c "$@"
fi
