#!/bin/bash

set -e

arch=$(uname -m)

yum install --quiet -y findutils jq tar gzip zsh git diffutils wget \
  tree unzip openssl gettext bash-completion python3 python3-pip \
  nc yum-utils

pip3 install -q awscurl==0.28 urllib3==1.26.6

# aws cli v2
curl --location --show-error --silent "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "awscliv2.zip"
unzip -o -q awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws awscliv2.zip

# git-remote-s3
pip install git-remote-s3

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
