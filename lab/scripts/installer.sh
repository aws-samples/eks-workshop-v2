#!/bin/bash

set -e

kubectl_version='1.27.7'
kubectl_checksum='e5fe510ba6f421958358d3d43b3f0b04c2957d4bc3bb24cf541719af61a06d79'

helm_version='3.10.1'
helm_checksum='c12d2cd638f2d066fec123d0bd7f010f32c643afdf288d39a4610b1f9cb32af3'

eksctl_version='0.164.0'
eksctl_checksum='2ed5de811dd26a3ed041ca3e6f26717288dc02dfe87ac752ae549ed69576d03e'

kubeseal_version='0.18.4'
kubeseal_checksum='2e765b87889bfcf06a6249cde8e28507e3b7be29851e4fac651853f7638f12f3'

yq_version='4.30.4'
yq_checksum='30459aa144a26125a1b22c62760f9b3872123233a5658934f7bd9fe714d7864d'

flux_version='2.1.0'
flux_checksum='fe6d32da40d5f876434e964c46bc07d00af138c560e063fdcfa8f73e37224087'

argocd_version='2.7.4'
argocd_checksum='1b9a5f7c47b3c1326a622533f073cef46511e391d296d9b075f583b474780356'

terraform_version='1.4.1'
terraform_checksum='9e9f3e6752168dea8ecb3643ea9c18c65d5a52acc06c22453ebc4e3fc2d34421'

ec2_instance_selector_version='2.4.1'
ec2_instance_selector_checksum='dfd6560a39c98b97ab99a34fc261b6209fc4eec87b0bc981d052f3b13705e9ff'

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
download_and_verify "https://get.helm.sh/helm-v$helm_version-linux-amd64.tar.gz" "$helm_checksum" "helm.tar.gz"
tar zxf helm.tar.gz
chmod +x linux-amd64/helm
mv ./linux-amd64/helm /usr/local/bin
rm -rf linux-amd64/ helm.tar.gz

# eksctl
download_and_verify "https://github.com/weaveworks/eksctl/releases/download/v$eksctl_version/eksctl_Linux_amd64.tar.gz" "$eksctl_checksum" "eksctl_Linux_amd64.tar.gz"
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
download_and_verify "https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_linux_amd64" "$yq_checksum" "yq"
chmod +x ./yq
mv ./yq /usr/local/bin

# flux
download_and_verify "https://github.com/fluxcd/flux2/releases/download/v${flux_version}/flux_${flux_version}_linux_amd64.tar.gz" "$flux_checksum" "flux.tar.gz"
tar zxf flux.tar.gz
chmod +x flux
mv ./flux /usr/local/bin
rm -rf flux.tar.gz

# terraform using Yum
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo && yum makecache fast
yum -y install terraform-1.5.5-1.x86_64

# argocd
download_and_verify "https://github.com/argoproj/argo-cd/releases/download/v${argocd_version}/argocd-linux-amd64" "$argocd_checksum" "argocd-linux-amd64"
chmod +x ./argocd-linux-amd64
mv ./argocd-linux-amd64 /usr/local/bin/argocd

# ec2 instance selector
download_and_verify "https://github.com/aws/amazon-ec2-instance-selector/releases/download/v${ec2_instance_selector_version}/ec2-instance-selector-linux-amd64" "$ec2_instance_selector_checksum" "ec2-instance-selector-linux-amd64"
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
