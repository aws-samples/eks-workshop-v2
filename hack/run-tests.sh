#!/bin/bash

environment_name=$1
module=$2

set -Eeuo pipefail
set -u
# Right now the container images are only designed for amd64
export DOCKER_DEFAULT_PLATFORM=linux/amd64

AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-""}

if [ ! -z "$AWS_DEFAULT_REGION" ]; then
  echo "Error: AWS_DEFAULT_REGION must be set"
  exit 1
fi

AWS_EKS_WORKSHOP_TEST_FLAGS=${AWS_EKS_WORKSHOP_TEST_FLAGS:-""}

if [[ "$module" == "*" ]]; then
  echo 'Error: Please specify a module'
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

echo "Building container images..."

container_image='eks-workshop-test'

(cd $SCRIPT_DIR/../lab && docker build -q -t eks-workshop-environment .)

(cd $SCRIPT_DIR/../test && docker build -q -t $container_image .)

aws_credential_args=""

ASSUME_ROLE=${ASSUME_ROLE:-""}

if [ ! -z "$ASSUME_ROLE" ]; then
  source $SCRIPT_DIR/lib/generate-aws-creds.sh

  aws_credential_args="-e 'AWS_ACCESS_KEY_ID' -e 'AWS_SECRET_ACCESS_KEY' -e 'AWS_SESSION_TOKEN'"
fi

echo "Running test suite..."

docker run --rm \
  -v $SCRIPT_DIR/../website/docs:/content \
  -v $SCRIPT_DIR/../manifests:/manifests \
  -e 'EKS_CLUSTER_NAME' -e 'AWS_DEFAULT_REGION' -e 'AWS_REGION' \
  $aws_credential_args $container_image -g "{$module,$module/**}" --hook-timeout 600 --timeout 1200 ${AWS_EKS_WORKSHOP_TEST_FLAGS}
