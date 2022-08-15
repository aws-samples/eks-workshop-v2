#!/bin/bash

terraform_context=$1
module=$2

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

terraform_dir="$SCRIPT_DIR/../$terraform_context"

export ASSUME_ROLE=$(terraform -chdir=$terraform_dir output -raw iam_role_arn)

TEMP='/tmp/eks-workshop-shell-env'

terraform -chdir=$terraform_dir output -raw environment_variables > $TEMP

container_image='public.ecr.aws/f2e3b2o6/eks-workshop:test-alpha.3'

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

docker run --rm --env-file /tmp/eks-workshop-shell-env \
  -v $SCRIPT_DIR/../website/docs:/content \
  -e "AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY" -e "AWS_SESSION_TOKEN" -e "AWS_DEFAULT_REGION" \
  $container_image -g "$module"