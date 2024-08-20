#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

outfile=$(mktemp)

cd lab

export Env="${EKS_CLUSTER_NAME}"

cat cfn/eks-workshop-vscode-cfn.yaml | yq '(.. | select(has("file"))) |= (load(.file))' | envsubst '$Env' > $outfile

echo "Output file: $outfile"