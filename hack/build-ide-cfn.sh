#!/bin/bash

set -e

output_path=$1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

if [ -z "$output_path" ]; then
  outfile=$(mktemp)
else
  outfile=$output_path
fi

cd lab

export Env="${EKS_CLUSTER_NAME}"

cat cfn/eks-workshop-vscode-cfn.yaml | yq '(.. | select(has("file"))) |= (load(.file))' | envsubst '$Env' > $outfile

echo "Output file: $outfile"