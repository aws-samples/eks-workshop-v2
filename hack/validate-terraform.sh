#!/bin/bash

set -e

environment=$1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

terraform_dir="$(mktemp -d)"
echo $terraform_dir

manifests_dir="${SCRIPT_DIR}/../manifests"

conf_dir="$terraform_dir/conf"

mkdir -p "$conf_dir"

cp $manifests_dir/.workshop/terraform/base.tf $conf_dir/base.tf

find $manifests_dir/modules -type d -name "terraform" -print0 | while read -d $'\0' file
do
  md5=$(echo ${file#"$manifests_dir/modules/"} | md5sum | cut -f1 -d" " | cut -d'/' -f1 | rev) # In case of non-unique
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

  eks_cluster_id            = local.eks_cluster_id
  eks_cluster_version       = local.eks_cluster_version
  cluster_security_group_id = local.cluster_security_group_id
  addon_context             = local.addon_context
  tags                      = local.tags
  resources_precreated      = var.resources_precreated
}
EOF
done

terraform -chdir="${conf_dir}" init -backend=false

echo ""
echo "Validating ${conf_dir}"
echo ""

terraform -chdir="${conf_dir}" validate