#!/bin/sh -x

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "We need a k8s version and eksctl version to update to, e.g. ./$0 1.29.0 0.169.0"
    exit 1
fi

K8SLong=$1
K8S="${K8SLong%.*}"
EKSCTL=$2

ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

#AMI=`aws ec2 describe-images     --owners amazon     --filters "Name=name,Values=amazon-eks-node-$K8S*" --query "Images[1].[Name,Description]" --output text`
AMI_API=`aws ec2 describe-images     --owners amazon     --filters "Name=name,Values=amazon-eks-node-$K8S*" --query "Images[1].[Name]" --output text`

AMI=$( echo ${AMI_API} | sed "s/amazon-eks-node-.*-v\(.*\)/$K8SLong-\\1/")


sed -i "s/KUBERNETES_VERSION: '.*'/KUBERNETES_VERSION: '$K8S'/" website/docusaurus.config.js
sed -i "s/KUBERNETES_NODE_VERSION: '.*'/KUBERNETES_NODE_VERSION: '$K8S-eks-tbdl'/" website/docusaurus.config.js #Find the right version

sed -i "s/kubectl_version='.*'/kubectl_version='$K8SLong'/" lab/scripts/installer.sh
kubectl_checksum=`curl -L "https://dl.k8s.io/release/v$K8SLong/bin/linux/amd64/kubectl.sha256"`
sed -i "s/kubectl_checksum='.*'/kubectl_checksum='$kubectl_checksum'/" lab/scripts/installer.sh

sed -i "s/eksctl_version='.*'/eksctl_version='$EKSCTL'/" lab/scripts/installer.sh
EKSCTL_CHECKSUM=`curl -sL "https://github.com/eksctl-io/eksctl/releases/download/v$EKSCTL/eksctl_checksums.txt" | grep $PLATFORM | cut -f1 -d" "`
sed -i "s/eksctl_checksum='.*'/eksctl_checksum='$EKSCTL_CHECKSUM'/" lab/scripts/installer.sh

#sed -i "s/version: '.*'/version: '$K8S'/" cluster/eksctl/cluster.yaml
yq -i ".metadata.version = \"$K8S\"" cluster/eksctl/cluster.yaml
yq -i ".managedNodeGroups[0].releaseVersion = \"$AMI\"" cluster/eksctl/cluster.yaml

# Using line numbers in Terraform to target only the right resources
sed -i "9s/default.*= \".*\"/default     = \"$K8S\"/" cluster/terraform/variables.tf
sed -i "15s/default.*= \".*\"/default     = \"$AMI\"/" cluster/terraform/variables.tf


sed -i "s/KUBECTL_VERSION='.*'/KUBECTL_VERSION='v$K8SLong'/" hack/lib/kubectl-version.sh