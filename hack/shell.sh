#!/bin/bash

terraform_context=$1
shell_command=$2

set -Eeuo pipefail

# You can run script with finch like CONTAINER_CLI=finch ./shell.sh <terraform_context> <shell_command>
CONTAINER_CLI=${CONTAINER_CLI:-docker}

# Right now the container images are only designed for amd64
export DOCKER_DEFAULT_PLATFORM=linux/amd64

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/terraform-context.sh

echo "Building container images..."

container_image='eks-workshop-environment'

(cd $SCRIPT_DIR/../environment && $CONTAINER_CLI build -q -t $container_image .)

source $SCRIPT_DIR/lib/generate-aws-creds.sh

command_args=""

echo "Starting shell in container..."

$CONTAINER_CLI run --rm -it --env-file /tmp/eks-workshop-shell-env \
  -v $SCRIPT_DIR/../environment/workspace:/workspace \
  -e "AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY" -e "AWS_SESSION_TOKEN" \
  $container_image $shell_command
