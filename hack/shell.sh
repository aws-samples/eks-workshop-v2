#!/bin/bash

if [ -z "$AWS_DEFAULT_REGION" ]; then
  echo 'Please set $AWS_DEFAULT_REGION'
  exit 1
fi

set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

state_path="$SCRIPT_DIR/../terraform/local/terraform.tfstate"

if [ ! -f "$state_path" ]; then
  echo "Error: Terraform state file does not exist, did you create the infrastructure?"
  exit 1
fi

export ASSUME_ROLE=$(terraform output -state $state_path -raw iam_role_arn)

TEMP='/tmp/eks-workshop-shell-env'

terraform output -state $state_path -raw environment_variables > $TEMP

container_image='public.ecr.aws/f2e3b2o6/eks-workshop:environment-alpha.1'

if [ -n "${DEV_MODE-}" ]; then
  echo "Building container images..."

  (cd $SCRIPT_DIR/../environment && docker build -q -t eks-workshop-environment .)

  container_image='eks-workshop-environment'
fi

echo "Generating temporary AWS credentials..."

ACCESS_VARS=$(aws sts assume-role --role-arn $ASSUME_ROLE --role-session-name eks-workshop-shell | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId) AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey) AWS_SESSION_TOKEN=\(.SessionToken)"')

# TODO: This should probably not use eval
eval "$ACCESS_VARS"

echo "Starting shell in container..."

docker run --rm -v $SCRIPT_DIR/../site/content:/content -it \
  -e "AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY" -e "AWS_SESSION_TOKEN" -e "AWS_DEFAULT_REGION" \
  --env-file /tmp/eks-workshop-shell-env \
  $container_image