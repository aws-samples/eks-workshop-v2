#!/bin/bash

set -e

kubectl_version='1.23.9'
kubectl_checksum='053561f7c68c5a037a69c52234e3cf1f91798854527692acd67091d594b616ce'

helm_version='3.10.1'
helm_checksum='c12d2cd638f2d066fec123d0bd7f010f32c643afdf288d39a4610b1f9cb32af3'

eksctl_version='0.144.0'
eksctl_checksum='f91a12e7f72bce41a2529053d3a22351ba1fd9bb3517f9d1d1ee74dda1e43afc'

kustomize_version='4.5.7'
kustomize_checksum='701e3c4bfa14e4c520d481fdf7131f902531bfc002cb5062dcf31263a09c70c9'

kubeseal_version='0.18.4'
kubeseal_checksum='2e765b87889bfcf06a6249cde8e28507e3b7be29851e4fac651853f7638f12f3'

yq_version='4.30.4'
yq_checksum='30459aa144a26125a1b22c62760f9b3872123233a5658934f7bd9fe714d7864d'

flux_version='0.38.3'
flux_checksum='268b8d9a2fa5b0c9e462b551eaefdadb9e03370eb53061a88a2a9ac40e95e8e4'

argocd_version='2.6.6'
argocd_checksum='d3ed61494dba51fff3e8568da7c38f620622f04d5cc2c3310d5c28ca66d7b033'

terraform_version='1.4.1'
terraform_checksum='9e9f3e6752168dea8ecb3643ea9c18c65d5a52acc06c22453ebc4e3fc2d34421'

download_and_verify () {
  url=$1
  checksum=$2
  out_file=$3

  curl --location --show-error --silent --output $out_file $url

  echo "$checksum $out_file" > "$out_file.sha256"
  sha256sum --check "$out_file.sha256"
  
  rm "$out_file.sha256"
}

yum install --quiet -y findutils jq tar gzip zsh git diffutils wget tree unzip openssl gettext bash-completion python3 pip3 python3-pip amazon-linux-extras

pip3 install awscurl

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

# kustomize
download_and_verify "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${kustomize_version}/kustomize_v${kustomize_version}_linux_amd64.tar.gz" "$kustomize_checksum" "kustomize.tar.gz"
tar zxf kustomize.tar.gz
chmod +x kustomize
mv ./kustomize /usr/local/bin
rm -rf kustomize.tar.gz

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

# terraform
download_and_verify "https://releases.hashicorp.com/terraform/1.4.1/terraform_1.4.1_linux_amd64.zip" "$terraform_checksum" "terraform.zip"
unzip -o terraform.zip
chmod +x terraform
mv ./terraform /usr/local/bin
rm -rf terraform.zip

# argocd
download_and_verify "https://github.com/argoproj/argo-cd/releases/download/v${argocd_version}/argocd-linux-amd64" "$argocd_checksum" "argocd-linux-amd64"
chmod +x ./argocd-linux-amd64
mv ./argocd-linux-amd64 /usr/local/bin/argocd

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
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/delete-all-if-crd-exists | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/delete-all-if-crd-exists
fi

mkdir -p /eks-workshop

chown ec2-user /eks-workshop
