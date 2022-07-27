#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PROJECT_ROOT="$SCRIPT_DIR/.."

TERRAFORM_DIR="$PROJECT_ROOT/terraform/local"

# Deletion procedure reflects recommendations from EKS Blueprints: 
# https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.6.0/getting-started/#cleanup

terraform -chdir=$TERRAFORM_DIR destroy -target=module.cluster.module.eks-blueprints-kubernetes-addons --auto-approve
terraform -chdir=$TERRAFORM_DIR destroy -target=module.cluster.module.descheduler --auto-approve

terraform -chdir=$TERRAFORM_DIR destroy -target=module.cluster.module.aws-eks-accelerator-for-terraform --auto-approve

terraform -chdir=$TERRAFORM_DIR destroy --auto-approve