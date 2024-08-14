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
  source /home/ec2-user/.bashrc.d/env.bash
  bash -c "$@"
fi