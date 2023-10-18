#!/bin/bash

environment=$1
shell_command=$2

set -Eeuo pipefail

# You can run script with finch like CONTAINER_CLI=finch ./shell.sh <terraform_context> <shell_command>
CONTAINER_CLI=${CONTAINER_CLI:-docker}

# Right now the container images are only designed for amd64
export DOCKER_DEFAULT_PLATFORM=linux/amd64

AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-""}

if [ ! -z "$AWS_DEFAULT_REGION" ]; then
  echo "Error: AWS_DEFAULT_REGION must be set"
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

echo "Building container images..."

container_image='eks-workshop-environment'

(cd $SCRIPT_DIR/../lab && $CONTAINER_CLI build -q -t $container_image .)

aws_credential_args=""

ASSUME_ROLE=${ASSUME_ROLE:-""}

if [ ! -z "$ASSUME_ROLE" ]; then
  source $SCRIPT_DIR/lib/generate-aws-creds.sh

  aws_credential_args="-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
fi

command_args=""

aws_credential_args="-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}"
echo "AWS Credentials used ${aws_credential_args}"

echo "Starting shell in container... with cluster name ${EKS_CLUSTER_NAME}"

$CONTAINER_CLI run --rm -it \
  -v $SCRIPT_DIR/../manifests:/manifests \
  -e 'EKS_CLUSTER_NAME' -e 'AWS_REGION' \
  $aws_credential_args $container_image $shell_command