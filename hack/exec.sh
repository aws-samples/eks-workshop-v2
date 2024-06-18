#!/bin/bash

environment=$1
shift 1
shell_command=$@

set -Eeuo pipefail

# You can run script with finch like CONTAINER_CLI=finch ./shell.sh <terraform_context> <shell_command>
CONTAINER_CLI=${CONTAINER_CLI:-docker}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

echo "Building container images..."

container_image='eks-workshop-environment'

(cd $SCRIPT_DIR/../lab && $CONTAINER_CLI build -q -t $container_image .)

source $SCRIPT_DIR/lib/generate-aws-creds.sh

echo "Executing command in container..."

$CONTAINER_CLI run --rm \
  -v $SCRIPT_DIR/../manifests:/manifests \
  -v $SCRIPT_DIR/../cluster:/cluster \
  --entrypoint /bin/bash \
  -e 'EKS_CLUSTER_NAME' -e 'AWS_REGION' \
  $aws_credential_args $container_image -c "$shell_command"