#!/bin/bash

set -e

bash /tmp/setup.sh

if [ ! -z "$EKS_CLUSTER_NAME" ]; then
  use-cluster $EKS_CLUSTER_NAME
fi

if [ $# -eq 0 ]
  then
    bash -l
else
  bash -c "$@"
fi
