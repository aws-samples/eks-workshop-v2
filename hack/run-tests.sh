#!/bin/bash

environment=$1
module=$2
glob=$3

set -Eeuo pipefail
set -u

# You can run script with finch like CONTAINER_CLI=finch ./run-tests.sh <terraform_context> <module>
CONTAINER_CLI=${CONTAINER_CLI:-docker}

# Right now the container images are only designed for amd64
export DOCKER_DEFAULT_PLATFORM=linux/amd64

AWS_EKS_WORKSHOP_TEST_FLAGS=${AWS_EKS_WORKSHOP_TEST_FLAGS:-""}

if [[ "$module" == '-' && "$glob" == '-' ]]; then
  echo 'Error: Please specify a module or a glob'
  exit 1
fi

actual_glob=''

if [[ "$glob" != '-' ]]; then
  actual_glob="$glob"
elif [[ "$module" != '-' ]]; then
  actual_glob="{$module,$module/**}"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

echo "Building container images..."

container_image='eks-workshop-test'

(cd $SCRIPT_DIR/../lab && $CONTAINER_CLI build -q -t eks-workshop-environment .)

(cd $SCRIPT_DIR/../test && $CONTAINER_CLI build -q -t $container_image .)

aws_credential_args=""

ASSUME_ROLE=${ASSUME_ROLE:-""}

if [ ! -z "$ASSUME_ROLE" ]; then
  source $SCRIPT_DIR/lib/generate-aws-creds.sh

  aws_credential_args="-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
fi

BACKGROUND=${BACKGROUND:-""}

background_args="--rm"

if [ ! -z "$BACKGROUND" ]; then
  background_args="--detach"
fi

TEST_REPORT=${TEST_REPORT:-""}

output_volume_args=""
output_args=""

if [ ! -z "$TEST_REPORT" ]; then
  mkdir -p $SCRIPT_DIR/../test-output

  output_volume_args="-v $SCRIPT_DIR/../test-output:/test-output"
  output_args="--output xunit --output-path /test-output/test-report.xml"
fi

RESOURCES_PRECREATED=${RESOURCES_PRECREATED:-""}

echo "Running test suite..."

$CONTAINER_CLI run $background_args $output_volume_args \
  -v $SCRIPT_DIR/../website/docs:/content \
  -v $SCRIPT_DIR/../manifests:/manifests \
  -e 'EKS_CLUSTER_NAME' -e 'AWS_REGION' -e 'RESOURCES_PRECREATED' \
  $aws_credential_args $container_image -g "${actual_glob}" --hook-timeout 3600 --timeout 3600 $output_args ${AWS_EKS_WORKSHOP_TEST_FLAGS}
