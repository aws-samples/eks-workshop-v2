#!/bin/bash

environment=$1
action=$2

if [ -z $action ]; then
  action="plan"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo $SCRIPT_DIR

source $SCRIPT_DIR/lib/common-env.sh

terraform_dir="${SCRIPT_DIR}/../terraform-resources"
manifests_dir="${SCRIPT_DIR}/../manifests"

mkdir -p "$terraform_dir"

conf_dir="$terraform_dir/conf"

rm -rf $conf_dir

mkdir -p "$conf_dir"

cat << EOF > $conf_dir/backend_override.tf
terraform {
  backend "local" {
    path = "../terraform.tfstate"
  }
}
EOF

cp $manifests_dir/.workshop/terraform/base.tf $conf_dir/base.tf

find $manifests_dir/modules -type d -name "preprovision" -print0 | while read -d $'\0' file
do
  md5=$(echo ${file#"$manifests_dir/modules/"} | md5sum | cut -f1 -d" " | cut -d'/' -f1 | rev) # In case of non-unique
  first_path=$(echo ${file#"$manifests_dir/modules/"} | cut -d'/' -f1,2 | tr '/' '_')
  target="${first_path}-$md5"

  cp -R $file $conf_dir/$target

  cat << EOF > $conf_dir/$target.tf
module "gen-$target" {
  source = "./$target"

  eks_cluster_id = local.eks_cluster_id
  tags           = local.tags
}
EOF
done

terraform -chdir="${conf_dir}" init

approve_args=''
export
if [[ "$action" != 'plan' ]]; then
  approve_args='--auto-approve'
fi

terraform -chdir="${conf_dir}" "$action" -var="eks_cluster_id=$EKS_CLUSTER_NAME" $approve_args