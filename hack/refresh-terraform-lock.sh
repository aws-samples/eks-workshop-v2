#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

terraform_dir="$SCRIPT_DIR/../terraform"
lock_file="$terraform_dir/.terraform.lock.hcl"

(cd $terraform_dir && terraform providers lock -platform=windows_amd64 -platform=darwin_amd64 -platform=darwin_arm64 -platform=linux_amd64)

cp $lock_file $SCRIPT_DIR/../test/terraform
cp $lock_file $SCRIPT_DIR/../infrastructure/terraform