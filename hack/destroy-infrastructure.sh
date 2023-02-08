#!/bin/bash

environment=$1
terraform_context=$2

set -Eeuo pipefail

export ENVIRONMENT_NAME="eks-workshop"

if [ ! -z "$environment" ]; then
  export TF_VAR_environment_suffix=${environment}
  export ENVIRONMENT_NAME="eks-workshop-${environment}"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PROJECT_ROOT="$SCRIPT_DIR/.."

terraform_dir="$PROJECT_ROOT/$terraform_context"

terraform -chdir=$terraform_dir init -upgrade

# Deletion procedure reflects recommendations from EKS Blueprints: 
# https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.6.0/getting-started/#cleanup

echo "Deleting general addons..."
terraform -chdir=$terraform_dir destroy -target=module.cluster.module.eks_blueprints_kubernetes_addons --auto-approve

echo "Deleting descheduler addon..."
terraform -chdir=$terraform_dir destroy -target=module.cluster.module.descheduler --auto-approve

echo "Deleting core blueprints addons..."
terraform -chdir=$terraform_dir destroy -target=module.cluster.module.eks_blueprints --auto-approve

if [ -n "${DANGEROUS_CLEANUP-}" ]; then
  temp_file=$(mktemp)

  CLEANUP_ENVIRONMENT_NAME="$ENVIRONMENT_NAME" envsubst < $SCRIPT_DIR/lib/filter.yml > $temp_file

  awsweeper --dry-run $temp_file
fi

echo "Deleting everything else..."
terraform -chdir=$terraform_dir destroy --auto-approve
