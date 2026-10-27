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


if [ "${SKIP_CREDENTIALS:-0}" = "0" ] && [ "${USE_CURRENT_USER:-0}" = "0" ]; then
  echo "Passing temp AWS credentials"
  source $SCRIPT_DIR/lib/generate-aws-creds.sh
elif [ "${USE_CURRENT_USER:-0}" != "0" ]; then
  if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "No AWS_ACCESS_KEY_ID found, please check your AWS credentials"
    exit 1
  fi
  echo "Using USE_CURRENT_USER"
  aws_credential_args="-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN:-}"
else
  echo "Using DEFAULT no credentials passed"
  aws_credential_args=""
fi

echo "Executing command in container..."

$CONTAINER_CLI run --rm \
  -v $SCRIPT_DIR/../manifests:/manifests \
  -v $SCRIPT_DIR/../cluster:/cluster \
  --entrypoint /bin/bash \
  -e "RESET_NO_DELETE=true" \
  -e 'EKS_CLUSTER_NAME' -e 'EKS_CLUSTER_AUTO_NAME'  -e 'AWS_REGION' -e 'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI' -e RESOURCE_CODEBUILD_ROLE_ARN \
  $aws_credential_args $container_image -c "$shell_command"