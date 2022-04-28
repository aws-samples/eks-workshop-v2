#!/bin/bash

set -e

if [ ! -z "$CLUSTER_NAME" ]; then
  aws eks update-kubeconfig --name $CLUSTER_NAME
fi

bash -l