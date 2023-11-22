#!/bin/bash

environment=$1
module=$2
action=$3

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

terraform_dir="${SCRIPT_DIR}/../terraform-resources"

mkdir -p "$terraform_dir"

rm -f "${terraform_dir}/*.tf"

cp $SCRIPT_DIR/../manifests/.workshop/terraform/base.tf "${terraform_dir}/base.tf"

find $SCRIPT_DIR/../manifests/modules/$module -name "addon_infrastructure.tf" -exec bash -c 'target=$(echo $0 | md5sum | cut -f1 -d" ");cp $0 $1/$target.tf' '{}' $terraform_dir \;

terraform -chdir="${terraform_dir}" init

approve_args=''

if [[ "$action" != 'plan' ]]; then
  approve_args='--auto-approve'
fi

terraform -chdir="${terraform_dir}" "$action" -var="eks_cluster_id=$EKS_CLUSTER_NAME" $approve_args