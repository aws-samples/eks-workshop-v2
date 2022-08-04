#!/bin/bash

module=$1

if [ -z "$AWS_DEFAULT_REGION" ]; then
  echo 'Please set $AWS_DEFAULT_REGION'
  exit 1
fi

if [ -z "$module" ]; then
  module='*'
  echo "Running tests for all modules"
else
  echo "Running tests for module $module"
fi

set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

state_path="$SCRIPT_DIR/../terraform/local/terraform.tfstate"

if [ ! -f "$state_path" ]; then
  echo "Error: Terraform state file does not exist, did you create the infrastructure?"
  exit 1
fi

export EKS_CLUSTER_NAME=$(terraform output -state $state_path -raw eks_cluster_id)
export ASSUME_ROLE=$(terraform output -state $state_path -raw iam_role_arn)

container_image='public.ecr.aws/f2e3b2o6/eks-workshop:test-alpha.1'

if [ -n "${DEV_MODE-}" ]; then
  echo "Building container images..."

  (cd $SCRIPT_DIR/../environment && docker build -q -t eks-workshop-environment .)

  (cd $SCRIPT_DIR/../test && docker build -q -t eks-workshop-test .)

  container_image='eks-workshop-test'
fi

echo "Generating temporary AWS credentials..."

ACCESS_VARS=$(aws sts assume-role --role-arn $ASSUME_ROLE --role-session-name eks-workshop-test | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId) AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey) AWS_SESSION_TOKEN=\(.SessionToken)"')

# TODO: This should probably not use eval
eval "$ACCESS_VARS"

echo "Running test suite..."

docker run --rm -v $SCRIPT_DIR/../site/content:/content \
  -e "EKS_CLUSTER_NAME" -e "AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY" -e "AWS_SESSION_TOKEN" -e "AWS_DEFAULT_REGION" \
  $container_image -g "$module/**"