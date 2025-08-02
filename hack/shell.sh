#!/bin/bash

environment=$1
shell_command=$2

set -Eeuo pipefail

# You can run script with finch like CONTAINER_CLI=finch ./shell.sh <terraform_context> <shell_command>
CONTAINER_CLI=${CONTAINER_CLI:-docker}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

echo "Building container images..."

container_image='eks-workshop-environment'

(cd $SCRIPT_DIR/../lab && $CONTAINER_CLI build -q -t $container_image .)

source $SCRIPT_DIR/lib/generate-aws-creds.sh

interactive_args=""

if [ -z "$shell_command" ]; then
  echo "Starting shell in container..."
  interactive_args="-it"
else
  echo "Executing command in container..."
fi

dns_args=""

DOCKER_DNS_OVERRIDE=${DOCKER_DNS_OVERRIDE:-""}

if [ ! -z "$DOCKER_DNS_OVERRIDE" ]; then
  dns_args="--dns=$DOCKER_DNS_OVERRIDE"
fi

$CONTAINER_CLI run --rm $interactive_args $dns_args \
  -v $SCRIPT_DIR/../manifests:/eks-workshop/manifests \
  -v $SCRIPT_DIR/../cluster:/cluster \
  -e 'EKS_CLUSTER_NAME' -e 'AWS_REGION' \
  -p 8889:8889 \
  $aws_credential_args $container_image $shell_command