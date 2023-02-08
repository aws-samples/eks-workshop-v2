#!/bin/bash

environment=$1
terraform_context=$2

set -Eeuo pipefail

if [ ! -z "$environment" ]; then
  export TF_VAR_environment_suffix=${environment}
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PROJECT_ROOT="$SCRIPT_DIR/.."

terraform_dir="$PROJECT_ROOT/$terraform_context"

terraform -chdir=$terraform_dir init -upgrade

terraform -chdir=$terraform_dir apply --auto-approve
