#!/bin/bash

environment=$1

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

aws resourcegroupstaggingapi get-resources --tag-filters Key=env,Values=$EKS_CLUSTER_NAME --query 'ResourceTagMappingList[].ResourceARN'