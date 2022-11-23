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

# Deletion procedure reflects recommendations from EKS Blueprints: 
# https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.6.0/getting-started/#cleanup

echo "Deleting general addons..."
terraform -chdir=$terraform_dir destroy -target=module.cluster.module.eks-blueprints-kubernetes-addons --auto-approve

echo "Deleting descheduler addon..."
terraform -chdir=$terraform_dir destroy -target=module.cluster.module.descheduler --auto-approve

echo "Deleting core blueprints addons..."
terraform -chdir=$terraform_dir destroy -target=module.cluster.module.eks-blueprints --auto-approve

if [ -n "${DANGEROUS_CLEANUP-}" ]; then
  temp_file=$(mktemp)

  CLUSTER_ID="${environment}" envsubst < $SCRIPT_DIR/lib/filter.yml > $temp_file

  awsweeper --dry-run $temp_file
fi

echo "Deleting everything else..."
terraform -chdir=$terraform_dir destroy --auto-approve