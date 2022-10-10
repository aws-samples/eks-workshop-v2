#!/bin/bash

terraform_context=$1

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PROJECT_ROOT="$SCRIPT_DIR/.."

terraform_dir="$PROJECT_ROOT/$terraform_context"

# Deletion procedure reflects recommendations from EKS Blueprints: 
# https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.6.0/getting-started/#cleanup

terraform -chdir=$terraform_dir destroy -target=module.cluster.module.eks-blueprints-kubernetes-addons --auto-approve
terraform -chdir=$terraform_dir destroy -target=module.cluster.module.eks-blueprints-kubernetes-csi-addon --auto-approve
terraform -chdir=$terraform_dir destroy -target=module.cluster.module.descheduler --auto-approve

terraform -chdir=$terraform_dir destroy -target=module.cluster.module.aws-eks-accelerator-for-terraform --auto-approve

terraform -chdir=$terraform_dir destroy --auto-approve