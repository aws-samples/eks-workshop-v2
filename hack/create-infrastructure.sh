#!/bin/bash

environment=$1

set -Eeuo pipefail

if [ -z "$environment" ]; then
  export EKS_CLUSTER_NAME="eks-workshop"
else
  export EKS_CLUSTER_NAME="eks-workshop-${environment}"
fi

AWS_REGION=${AWS_REGION:-""}

if [ -z "$AWS_REGION" ]; then
  echo "Warning: Defaulting region to us-west-2"

  export AWS_REGION="us-west-2"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

root="$SCRIPT_DIR/.."

cat $root/cluster/eksctl/cluster.yaml | envsubst | eksctl create cluster -f -
