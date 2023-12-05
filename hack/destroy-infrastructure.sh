#!/bin/bash

environment=$1

set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

root="$SCRIPT_DIR/.."

cat $root/cluster/eksctl/cluster.yaml | envsubst | eksctl delete cluster --wait --force --disable-nodegroup-eviction -f -
