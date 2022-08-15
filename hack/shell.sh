#!/bin/bash

terraform_context=$1

if [ -z "$AWS_DEFAULT_REGION" ]; then
  echo 'Please set $AWS_DEFAULT_REGION'
  exit 1
fi

set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

terraform_dir="$SCRIPT_DIR/../$terraform_context"

export ASSUME_ROLE=$(terraform -chdir=$terraform_dir output -raw iam_role_arn)

TEMP='/tmp/eks-workshop-shell-env'

terraform -chdir=$terraform_dir output -raw environment_variables > $TEMP

container_image='public.ecr.aws/f2e3b2o6/eks-workshop:environment-alpha.3'

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

docker run --rm -it --env-file /tmp/eks-workshop-shell-env \
  -e "AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY" -e "AWS_SESSION_TOKEN" -e "AWS_DEFAULT_REGION" \
  $container_image