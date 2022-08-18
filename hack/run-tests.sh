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
  echo "Running tests for module pattern $module"
fi

set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/terraform-context.sh

container_image='public.ecr.aws/f2e3b2o6/eks-workshop:test-alpha.3'

if [ -n "${DEV_MODE-}" ]; then
  echo "Building container images..."

  (cd $SCRIPT_DIR/../environment && docker build -q -t eks-workshop-environment .)

  (cd $SCRIPT_DIR/../test && docker build -q -t eks-workshop-test .)

  container_image='eks-workshop-test'
fi

source $SCRIPT_DIR/lib/generate-aws-creds.sh

echo "Running test suite..."

docker run --rm --env-file /tmp/eks-workshop-shell-env \
  -v $SCRIPT_DIR/../website/docs:/content \
  -v $SCRIPT_DIR/../environment/workspace:/workspace \
  -e "AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY" -e "AWS_SESSION_TOKEN" -e "AWS_DEFAULT_REGION" \
  $container_image -g "$module"