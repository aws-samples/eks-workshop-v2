#!/bin/bash

set -e

environment=$1
action=${2:-"plan"}

# Optional module filter, as a path relative to manifests/modules, for example
# automation/gitops/argocd. Only preprovision directories under it are staged,
# which keeps a targeted run from applying every other module's pre-provisioned
# resources. '-' is the Makefile's "unset" value.
module_filter=${3:-${PREPROVISION_MODULE:-}}
if [ "$module_filter" = "-" ]; then
  module_filter=""
fi

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

# Modules that need IAM Identity Center mark themselves with a `.requires-idc` file in
# their preprovision directory, and the shared layer that creates it is staged only if
# at least one staged module asks for it. An unfiltered run stages every module, so in
# practice this is always on for a Workshop Studio event; the check earns its keep for
# a `module=`-filtered run, which must not enable Identity Center account-wide just to
# pre-provision a lab that has nothing to do with it.
#
# The layer lives in `.workshop/terraform`, outside `manifests/modules`, so the find
# below cannot pick it up as an ordinary module and no lab root can reach it through a
# `source`. Creating Identity Center therefore stays reachable from this script only.
idc_base_dir="$manifests_dir/.workshop/terraform/preprovision-base"
idc_base_target="preprovision-base"
idc_required=""

staged=0

# Read through process substitution rather than a pipe so the counter below is
# incremented in this shell and not in a subshell.
# Collected first rather than staged as we go, because whether any module needs
# Identity Center decides both if the shared layer is staged and whether the wrappers
# below carry a depends_on referring to it.
selected=()

while read -d $'\0' file
do
  relative_path=${file#"$manifests_dir/modules/"}

  if [ -n "$module_filter" ] && [[ "$relative_path" != "$module_filter"* ]]; then
    continue
  fi

  selected+=("$file")

  if [ -f "$file/.requires-idc" ]; then
    idc_required="yes"
  fi
done < <(find $manifests_dir/modules -type d -name "preprovision" -print0)

# Everything staged shares one Terraform root and one state file, so the shared layer
# is a module in the same apply rather than a separate root: no second state to
# configure, and a single `terraform apply` still describes the whole event.
#
# One root also means Terraform is free to reorder, and a module reading Identity
# Center through a data source could be evaluated before the layer that creates it.
# Hence the explicit depends_on on every wrapper below. It costs nothing for the
# modules that do not care, and without it the ordering is luck.
if [ -n "$idc_required" ]; then
  cp -R $idc_base_dir $conf_dir/$idc_base_target

  cat << EOF > $conf_dir/$idc_base_target.tf
module "gen_idc_base" {
  source = "./$idc_base_target"

  eks_cluster_id = local.eks_cluster_id
  tags           = local.tags
}
EOF

  echo "Staged the shared IAM Identity Center layer (requested by a module's .requires-idc)"
fi

for file in "${selected[@]}"
do
  relative_path=${file#"$manifests_dir/modules/"}

  md5=$(echo $relative_path | md5sum | cut -f1 -d" " | cut -d'/' -f1 | rev)
  first_path=$(echo $relative_path | cut -d'/' -f1,2 | tr '/' '_')
  target="${first_path}-$md5"

  cp -R $file $conf_dir/$target

  depends_on_idc=""
  if [ -n "$idc_required" ]; then
    depends_on_idc="
  depends_on = [module.gen_idc_base]
"
  fi

  cat << EOF > $conf_dir/$target.tf
module "gen-$target" {
  source = "./$target"
  providers = {
    helm.auto_mode = helm.auto_mode
    kubernetes.auto_mode = kubernetes.auto_mode
  }
$depends_on_idc
  eks_cluster_id = local.eks_cluster_id
  tags           = local.tags
}
EOF

  staged=$((staged + 1))
done

if [ -n "$module_filter" ]; then
  echo "Staged $staged preprovision directories matching '$module_filter'"

  if [ "$staged" = "0" ]; then
    echo "Error: no preprovision directory found under manifests/modules/$module_filter" >&2
    exit 1
  fi
fi

ls -la $conf_dir

terraform -chdir="${conf_dir}" init $backend_init_args

approve_args=''
if [[ "$action" != 'plan' ]]; then
  approve_args='--auto-approve'
fi

terraform -chdir="${conf_dir}" "$action" -var="eks_cluster_id=$EKS_CLUSTER_NAME" $approve_args
