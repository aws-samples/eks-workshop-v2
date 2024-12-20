#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

aws cloudformation delete-stack --stack-name "$EKS_CLUSTER_NAME-ide"
aws cloudformation wait stack-delete-complete --stack-name "$EKS_CLUSTER_NAME-ide"