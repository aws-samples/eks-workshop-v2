#!/bin/bash

terraform_context=$1
module=$2

set -Eeuo pipefail
set -u
# Right now the container images are only designed for amd64
export DOCKER_DEFAULT_PLATFORM=linux/amd64

AWS_EKS_WORKSHOP_TEST_FLAGS=${AWS_EKS_WORKSHOP_TEST_FLAGS:-""}

if [[ "$module" == "*" ]]; then
  echo 'Error: Please specify a module'
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/terraform-context.sh

echo "Building container images..."

container_image='eks-workshop-test'

(cd $SCRIPT_DIR/../environment && docker build -q -t eks-workshop-environment .)

(cd $SCRIPT_DIR/../test && docker build -q -t $container_image .)

source $SCRIPT_DIR/lib/generate-aws-creds.sh

echo "Running test suite..."

docker run --rm --env-file /tmp/eks-workshop-shell-env \
  -v $SCRIPT_DIR/../website/docs:/content \
  -v $SCRIPT_DIR/../environment/workspace:/workspace \
  -e "AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY" -e "AWS_SESSION_TOKEN" -e "AWS_DEFAULT_REGION" \
  $container_image -g "{$module,$module/**}" --hook-timeout 600 --timeout 1200 ${AWS_EKS_WORKSHOP_TEST_FLAGS}
