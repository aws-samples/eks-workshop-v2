#!/bin/bash

set -e

environment=$1
action=${2:-"plan"}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

# Allow overriding paths from outside (e.g. buildspec)
terraform_dir="${TERRAFORM_PREPROVISION_DIR:-${SCRIPT_DIR}/../terraform-resources}"
manifests_dir="${MANIFESTS_DIR:-${SCRIPT_DIR}/../manifests}"

mkdir -p "$terraform_dir"

conf_dir="$terraform_dir/conf"

rm -rf $conf_dir
mkdir -p "$conf_dir"

# Backend configuration: S3 or local
if [ -n "${TF_STATE_S3_BUCKET:-}" ]; then
  cat << EOF > $conf_dir/backend_override.tf
terraform {
  backend "s3" {}
}
EOF
  backend_init_args="--backend-config=bucket=${TF_STATE_S3_BUCKET} --backend-config=key=terraform.tfstate --backend-config=region=${AWS_REGION}"
else
  cat << EOF > $conf_dir/backend_override.tf
terraform {
  backend "local" {
    path = "../terraform.tfstate"
  }
}
EOF
  backend_init_args=""
fi

cp $manifests_dir/.workshop/terraform/base.tf $conf_dir/base.tf

find $manifests_dir/modules -type d -name "preprovision" -print0 | while read -d $'\0' file
do
  md5=$(echo ${file#"$manifests_dir/modules/"} | md5sum | cut -f1 -d" " | cut -d'/' -f1 | rev)
  first_path=$(echo ${file#"$manifests_dir/modules/"} | cut -d'/' -f1,2 | tr '/' '_')
  target="${first_path}-$md5"

  cp -R $file $conf_dir/$target

  cat << EOF > $conf_dir/$target.tf
module "gen-$target" {
  source = "./$target"
  providers = {
    helm.auto_mode = helm.auto_mode
    kubernetes.auto_mode = kubernetes.auto_mode
  }

  eks_cluster_id = local.eks_cluster_id
  tags           = local.tags
}
EOF
done

ls -la $conf_dir

terraform -chdir="${conf_dir}" init $backend_init_args

approve_args=''
if [[ "$action" != 'plan' ]]; then
  approve_args='--auto-approve'
fi

terraform -chdir="${conf_dir}" "$action" -var="eks_cluster_id=$EKS_CLUSTER_NAME" $approve_args
