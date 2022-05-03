#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PROJECT_ROOT="$SCRIPT_DIR/.."

TERRAFORM_DIR="$PROJECT_ROOT/terraform/cluster-only"

terraform -chdir=$TERRAFORM_DIR init

terraform -chdir=$TERRAFORM_DIR apply --auto-approve