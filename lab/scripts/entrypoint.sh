#!/bin/bash

set -e

bash /tmp/setup.sh

ln -s /eks-workshop/manifests /home/ec2-user/environment/eks-workshop

if [ ! -z "$EKS_CLUSTER_NAME" ]; then
  aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
fi

if [ $# -eq 0 ]; then
  bash -l
else
  if [[ "$1" == "ide" ]]; then
    bash /tmp/setup-ide.sh
    
    export PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)

    echo "--------------------------------------------------------"
    echo "Starting IDE with password $PASSWORD"
    echo "--------------------------------------------------------"

    exec code-server --bind-addr 0.0.0.0 --port 8889
  else
    exec bash -l -c "$@"
  fi
fi
