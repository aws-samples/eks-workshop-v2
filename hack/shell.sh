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

source $SCRIPT_DIR/lib/resolve-source-ip.sh

# reset-environment saves the current lab's cleanup.sh here so that the *next*
# prepare-environment can undo that lab before setting up the new one. The
# container runs with --rm, so this has to live on the host: otherwise the hook
# dies with the container and switching labs across two `make shell` invocations
# silently skips the previous lab's cleanup, leaving its workloads behind to
# collide with the sample application. Keyed by cluster so separate environments
# do not share hook state.
hooks_dir="$SCRIPT_DIR/../.workshop-state/$EKS_CLUSTER_NAME/hooks"
mkdir -p "$hooks_dir"

$CONTAINER_CLI run --rm $interactive_args $dns_args \
  -v $SCRIPT_DIR/../manifests:/eks-workshop/manifests \
  -v $hooks_dir:/eks-workshop/hooks \
  -v $SCRIPT_DIR/../cluster:/cluster \
  -e "RESET_NO_DELETE=true" \
  -e 'EKS_CLUSTER_NAME' -e 'EKS_CLUSTER_AUTO_NAME' -e 'AWS_REGION' -e 'BASE_INBOUND_CIDRS' \
  -e 'ARGOCD_ADMIN_EMAIL' \
  -p 8889:8889 \
  $aws_credential_args $container_image $shell_command