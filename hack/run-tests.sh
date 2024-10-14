#!/bin/bash

environment=$1
module=$2
glob=$3

set -Eeuo pipefail
set -u

container_name="eks-workshop-test-$(openssl rand -hex 4)"

# You can run script with finch like CONTAINER_CLI=finch ./run-tests.sh <terraform_context> <module>
CONTAINER_CLI=${CONTAINER_CLI:-docker}

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

(cd $SCRIPT_DIR/../testing && $CONTAINER_CLI build -q -t $container_image .)

source $SCRIPT_DIR/lib/generate-aws-creds.sh

BACKGROUND=${BACKGROUND:-""}

background_args=""

if [ ! -z "$BACKGROUND" ]; then
  background_args="--detach"
fi

TEST_REPORT=${TEST_REPORT:-""}

output_args=""

GENERATE_TIMINGS=${GENERATE_TIMINGS:-""}

if [ ! -z "$GENERATE_TIMINGS" ] && [ -z "$TEST_REPORT" ]; then
  export TEST_REPORT=$(mktemp)
  echo "Writing test output to temporary file $TEST_REPORT"
fi

if [ ! -z "$TEST_REPORT" ]; then
  output_args="--output json --output-path /tmp/test-report.json"
fi

dns_args=""

DOCKER_DNS_OVERRIDE=${DOCKER_DNS_OVERRIDE:-""}

if [ ! -z "$DOCKER_DNS_OVERRIDE" ]; then
  dns_args="--dns=$DOCKER_DNS_OVERRIDE"
fi

RESOURCES_PRECREATED=${RESOURCES_PRECREATED:-""}

echo "Running test suite..."

# get current IDs
USER_ID=$(id -u)
GROUP_ID=$(id -g)

exit_code=0

$CONTAINER_CLI run $background_args $dns_args \
  --name $container_name \
  -v $SCRIPT_DIR/../website/docs:/content \
  -v $SCRIPT_DIR/../manifests:/eks-workshop/manifests \
  -e 'EKS_CLUSTER_NAME' -e 'AWS_REGION' -e 'RESOURCES_PRECREATED' \
  $aws_credential_args $container_image -g "${actual_glob}" --hook-timeout 3600 --timeout 3600 $output_args ${AWS_EKS_WORKSHOP_TEST_FLAGS} || exit_code=$?

if [ $exit_code -eq 0 ]; then
  if [ ! -z "$TEST_REPORT" ]; then
    docker cp $container_name:/tmp/test-report.json $TEST_REPORT > /dev/null
  fi
fi

docker rm $container_name > /dev/null

if [ $exit_code -ne 0 ]; then
    exit $exit_code
fi

if [ ! -z "$GENERATE_TIMINGS" ]; then
  tmpfile=$(mktemp)

  cat $TEST_REPORT | jq '[.tests[] | {(.file | sub("^/content"; "")): .duration}] | add' > $tmpfile

  outtmpfile=$(mktemp)

  jq -s '.[0] * .[1] | to_entries | sort_by(.key) | from_entries' $SCRIPT_DIR/../website/test-durations.json $tmpfile > $outtmpfile
  mv $outtmpfile $SCRIPT_DIR/../website/test-durations.json
fi