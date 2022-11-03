#!/bin/bash

terraform_context=$1

set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/terraform-context.sh

container_image='public.ecr.aws/f2e3b2o6/eks-workshop:environment-alpha.3'

if [ -n "${PREBUILT-}" ]; then
  echo "Using pre-built images"
else
  echo "Building container images..."

  (cd $SCRIPT_DIR/../environment && docker build -q -t eks-workshop-environment .)

  container_image='eks-workshop-environment'
fi

source $SCRIPT_DIR/lib/generate-aws-creds.sh

# Right now the container images are only designed for amd64
export DOCKER_DEFAULT_PLATFORM=linux/amd64 

echo "Starting shell in container..."

docker run --rm -it --env-file /tmp/eks-workshop-shell-env \
  -v $SCRIPT_DIR/../environment/workspace:/workspace \
  -e "AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY" -e "AWS_SESSION_TOKEN" \
  $container_image