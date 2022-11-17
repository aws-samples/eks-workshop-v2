#!/bin/bash

set -e

kubectl_version='1.23.9'
kubectl_checksum='053561f7c68c5a037a69c52234e3cf1f91798854527692acd67091d594b616ce'

helm_version='3.10.1'
helm_checksum='c12d2cd638f2d066fec123d0bd7f010f32c643afdf288d39a4610b1f9cb32af3'

eksctl_version='0.115.0'
eksctl_checksum='d1d6d6d56ae33f47242f769bea4b19587f1200e5bbef65f3a35d159ed2463716'

download_and_verify () {
  url=$1
  checksum=$2
  out_file=$3

  curl --location --show-error --silent --output $out_file $url

  echo "$checksum $out_file" > "$out_file.sha256"
  sha256sum --check "$out_file.sha256"
  
  rm "$out_file.sha256"
}

yum install -y findutils jq tar gzip zsh git diffutils wget tree unzip openssl gettext bash-completion python3 pip3 python3-pip amazon-linux-extras

amazon-linux-extras install -y postgresql12

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

# aws cli v2
curl --location --show-error --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o -q awscliv2.zip
./aws/install
rm -rf ./aws awscliv2.zip

# kubeseal version 0.18.0
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/kubeseal-0.18.0-linux-amd64.tar.gz
tar xfz kubeseal-0.18.0-linux-amd64.tar.gz
install -m 755 kubeseal /usr/local/bin/kubeseal
