#!/bin/bash

environment=$1
terraform_context=$2

set -Eeuo pipefail

if [ -z "$environment" ]; then
  echo 'Error: Must provide environment name'
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PROJECT_ROOT="$SCRIPT_DIR/.."

terraform_dir="$PROJECT_ROOT/$terraform_context"

export TF_VAR_id=${environment} TF_VAR_cluster_id=${environment}

terraform -chdir=$terraform_dir init -lockfile=readonly

terraform -chdir=$terraform_dir apply --auto-approve