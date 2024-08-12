#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

outfile=$(mktemp)

cd lab

export Account='${AWS::AccountId}'
export Region='${AWS::Region}'
export Environment='eks-workshop'

cat cfn/eks-workshop-vscode-cfn.yaml | yq '(.. | select(has("file"))) |= (load(.file) | (.Statement[].Resource[] |= {"Fn::Sub": [., {}]})  )' | envsubst '$Account $Region $Environment' > $outfile

# 

echo "Output file: $outfile"