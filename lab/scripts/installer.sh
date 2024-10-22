#!/bin/bash

set -e

# renovate: depName=kubernetes/kubernetes
kubectl_version='1.30.5'

# renovate: depName=helm/helm
helm_version='3.16.1'

# renovate: depName=eksctl-io/eksctl
eksctl_version='0.194.0'

kubeseal_version='0.18.4'

# renovate: depName=mikefarah/yq
yq_version='4.44.3'

# renovate: depName=fluxcd/flux2
flux_version='2.4.0'

# renovate: depName=argoproj/argo-cd
argocd_version='2.12.4'

# renovate: depName=hashicorp/terraform
terraform_version='1.9.6'

# renovate: depName=aws/amazon-ec2-instance-selector
ec2_instance_selector_version='2.4.1'

# renovate: depName=hatoo/oha
oha_version='1.4.6'

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

arch=$(uname -m)
arch_name=""

# Convert to amd64 or arm64
case "$arch" in
  x86_64)
    arch_name="amd64"
    ;;
  aarch64)
    arch_name="arm64"
    ;;
  *)
    echo "Unsupported architecture: $arch"
    exit 1
    ;;
esac

yum install --quiet -y findutils jq tar gzip zsh git diffutils wget \
  tree unzip openssl gettext bash-completion python3 python3-pip \
  nc yum-utils

pip3 install -q awscurl==0.28 urllib3==1.26.6

# kubectl
download "https://dl.k8s.io/release/v$kubectl_version/bin/linux/${arch_name}/kubectl" "kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin

# helm
download "https://get.helm.sh/helm-v$helm_version-linux-${arch_name}.tar.gz" "helm.tar.gz"
tar zxf helm.tar.gz
chmod +x linux-${arch_name}/helm
mv ./linux-${arch_name}/helm /usr/local/bin
rm -rf linux-${arch_name}/ helm.tar.gz

# eksctl
download "https://github.com/weaveworks/eksctl/releases/download/v$eksctl_version/eksctl_Linux_${arch_name}.tar.gz" "eksctl.tar.gz"
tar zxf eksctl.tar.gz
chmod +x eksctl
mv ./eksctl /usr/local/bin
rm -rf eksctl.tar.gz

# aws cli v2
curl --location --show-error --silent "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "awscliv2.zip"
unzip -o -q awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws awscliv2.zip

# kubeseal
download "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${kubeseal_version}/kubeseal-${kubeseal_version}-linux-${arch_name}.tar.gz" "kubeseal.tar.gz"
tar xfz kubeseal.tar.gz
chmod +x kubeseal
mv ./kubeseal /usr/local/bin
rm -rf kubeseal.tar.gz

# yq
download "https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_linux_${arch_name}" "yq"
chmod +x ./yq
mv ./yq /usr/local/bin

# flux
download "https://github.com/fluxcd/flux2/releases/download/v${flux_version}/flux_${flux_version}_linux_${arch_name}.tar.gz" "flux.tar.gz"
tar zxf flux.tar.gz
chmod +x flux
mv ./flux /usr/local/bin
rm -rf flux.tar.gz

# terraform
download "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_${arch_name}.zip" "terraform.zip"
unzip -o -q terraform.zip -d /tmp
chmod +x /tmp/terraform
mv /tmp/terraform /usr/local/bin
rm -f terraform.zip

# argocd
download "https://github.com/argoproj/argo-cd/releases/download/v${argocd_version}/argocd-linux-${arch_name}" "argocd"
chmod +x ./argocd
mv ./argocd /usr/local/bin/argocd

# ec2 instance selector
download "https://github.com/aws/amazon-ec2-instance-selector/releases/download/v${ec2_instance_selector_version}/ec2-instance-selector-linux-${arch_name}" "ec2-instance-selector"
chmod +x ./ec2-instance-selector
mv ./ec2-instance-selector /usr/local/bin/ec2-instance-selector

# oha
download "https://github.com/hatoo/oha/releases/download/v${oha_version}/oha-linux-${arch_name}" "oha"
chmod +x ./oha
mv ./oha /usr/local/bin

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
