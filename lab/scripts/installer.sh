#!/bin/bash

set -e

kubectl_version='1.29.0'
kubectl_checksum='0e03ab096163f61ab610b33f37f55709d3af8e16e4dcc1eb682882ef80f96fd5'

# renovate: depName=helm/helm
helm_version='3.14.4'

# renovate: depName=eksctl-io/eksctl
eksctl_version='0.175.0'

kubeseal_version='0.18.4'
kubeseal_checksum='2e765b87889bfcf06a6249cde8e28507e3b7be29851e4fac651853f7638f12f3'

# renovate: depName=mikefarah/yq
yq_version='4.43.1'

# renovate: depName=fluxcd/flux2
flux_version='2.2.3'

# renovate: depName=argoproj/argo-cd
argocd_version='2.10.9'

# renovate: depName=hashicorp/terraform
terraform_version='1.8.2'

# renovate: depName=aws/amazon-ec2-instance-selector
ec2_instance_selector_version='2.4.1'

download () {
  url=$1
  out_file=$2

  curl --location --show-error --silent --output $out_file $url
}

download_and_verify () {
  url=$1
  checksum=$2
  out_file=$3

  curl --location --show-error --silent --output $out_file $url

  echo "$checksum $out_file" > "$out_file.sha256"
  sha256sum --check "$out_file.sha256"

  rm "$out_file.sha256"
}

yum install --quiet -y findutils jq tar gzip zsh git diffutils wget \
  tree unzip openssl gettext bash-completion python3 pip3 python3-pip \
  amazon-linux-extras nc yum-utils

pip3 install -q awscurl==0.28 urllib3==1.26.6

# kubectl
download_and_verify "https://dl.k8s.io/release/v$kubectl_version/bin/linux/amd64/kubectl" "$kubectl_checksum" "kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin

# helm
download "https://get.helm.sh/helm-v$helm_version-linux-amd64.tar.gz" "helm.tar.gz"
tar zxf helm.tar.gz
chmod +x linux-amd64/helm
mv ./linux-amd64/helm /usr/local/bin
rm -rf linux-amd64/ helm.tar.gz

# eksctl
download "https://github.com/weaveworks/eksctl/releases/download/v$eksctl_version/eksctl_Linux_amd64.tar.gz" "eksctl_Linux_amd64.tar.gz"
tar zxf eksctl_Linux_amd64.tar.gz
chmod +x eksctl
mv ./eksctl /usr/local/bin
rm -rf eksctl_Linux_amd64.tar.gz

# aws cli v2
curl --location --show-error --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o -q awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws awscliv2.zip

# kubeseal
download_and_verify "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${kubeseal_version}/kubeseal-${kubeseal_version}-linux-amd64.tar.gz" "$kubeseal_checksum" "kubeseal.tar.gz"
tar xfz kubeseal.tar.gz
chmod +x kubeseal
mv ./kubeseal /usr/local/bin
rm -rf kubeseal.tar.gz

# yq
download "https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_linux_amd64" "yq"
chmod +x ./yq
mv ./yq /usr/local/bin

# flux
download "https://github.com/fluxcd/flux2/releases/download/v${flux_version}/flux_${flux_version}_linux_amd64.tar.gz" "flux.tar.gz"
tar zxf flux.tar.gz
chmod +x flux
mv ./flux /usr/local/bin
rm -rf flux.tar.gz

# terraform
download "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" "terraform.zip"
unzip -o -q terraform.zip -d /tmp
chmod +x /tmp/terraform
mv /tmp/terraform /usr/local/bin
rm -f terraform.zip

# argocd
download "https://github.com/argoproj/argo-cd/releases/download/v${argocd_version}/argocd-linux-amd64" "argocd-linux-amd64"
chmod +x ./argocd-linux-amd64
mv ./argocd-linux-amd64 /usr/local/bin/argocd

# ec2 instance selector
download "https://github.com/aws/amazon-ec2-instance-selector/releases/download/v${ec2_instance_selector_version}/ec2-instance-selector-linux-amd64" "ec2-instance-selector-linux-amd64"
chmod +x ./ec2-instance-selector-linux-amd64
mv ./ec2-instance-selector-linux-amd64 /usr/local/bin/ec2-instance-selector

REPOSITORY_OWNER=${REPOSITORY_OWNER:-"aws-samples"}
REPOSITORY_NAME=${REPOSITORY_NAME:-"eks-workshop-v2"}

if [ ! -z "$REPOSITORY_REF" ]; then
  cat << EOT > /usr/local/bin/reset-environment
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/reset-environment | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/reset-environment
  cat << EOT > /usr/local/bin/delete-environment
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/delete-environment | bash
EOT
  chmod +x /usr/local/bin/delete-environment
  cat << EOT > /usr/local/bin/wait-for-lb
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/wait-for-lb | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/wait-for-lb
  cat << EOT > /usr/local/bin/use-cluster
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/use-cluster | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/use-cluster
  cat << EOT > /usr/local/bin/awshttp
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/awshttp | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/awshttp
  cat << EOT > /usr/local/bin/delete-all-if-crd-exists
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/delete-all-if-crd-exists | bash -s -- \$@
EOT
  chmod +x /usr/local/bin/delete-all-if-crd-exists
  cat << EOT > /usr/local/bin/delete-all-and-wait-if-crd-exists
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/delete-all-and-wait-if-crd-exists | bash -s -- \$@
EOT
  chmod +x /usr/local/bin/delete-all-and-wait-if-crd-exists
  cat << EOT > /usr/local/bin/delete-nodegroup
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/delete-nodegroup | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/delete-nodegroup
  cat << EOT > /usr/local/bin/uninstall-helm-chart
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/uninstall-helm-chart | bash -s -- \$@
EOT
  chmod +x /usr/local/bin/uninstall-helm-chart
  cat << EOT > /usr/local/bin/update-ide
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/update-ide | bash
EOT
  chmod +x /usr/local/bin/update-ide
fi

mkdir -p /eks-workshop

chown ec2-user /eks-workshop
