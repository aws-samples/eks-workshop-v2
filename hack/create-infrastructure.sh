#!/bin/bash

terraform_context=$1

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PROJECT_ROOT="$SCRIPT_DIR/.."

terraform_dir="$PROJECT_ROOT/$terraform_context"

terraform -chdir=$terraform_dir init

terraform -chdir=$terraform_dir apply --auto-approve