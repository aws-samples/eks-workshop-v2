#!/bin/bash

set -Eeuo pipefail

if [ -z "$ASSUME_ROLE" ]; then
  echo "Must set ASSUME_ROLE environment variable"
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

state_path="$SCRIPT_DIR/../terraform/cluster-only/terraform.tfstate"

if [ ! -f "$state_path" ]; then
  echo "Error: Terraform state file does not exist, did you create the infrastructure?"
  exit 1
fi

export EKS_CLUSTER_NAME=$(terraform output -state $state_path -raw eks_cluster_id)

echo "Generating temporary AWS credentials..."

ACCESS_VARS=$(aws sts assume-role --role-arn $ASSUME_ROLE --role-session-name eks-workshop-shell | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId) AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey) AWS_SESSION_TOKEN=\(.SessionToken)"')

echo "Building container images..."

(cd $SCRIPT_DIR/../environment && docker build -q -t eks-workshop-environment .)

# TODO: This should probably not use eval
eval "$ACCESS_VARS"

echo "Starting shell in container..."

docker run -v $SCRIPT_DIR/../site/content:/content -it \
  -e "EKS_CLUSTER_NAME" -e "AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY" -e "AWS_SESSION_TOKEN" -e "AWS_DEFAULT_REGION" \
  eks-workshop-environment