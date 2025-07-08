#!/bin/bash

set -e

if [[ ! -d "~/.bashrc.d" ]]; then
  mkdir -p ~/.bashrc.d
  
  touch ~/.bashrc.d/dummy.bash

  echo 'for file in ~/.bashrc.d/*.bash; do source "$file"; done' >> ~/.bashrc
fi

if [ ! -z "$CLOUD9_ENVIRONMENT_ID" ]; then
  echo "aws cloud9 update-environment --environment-id $CLOUD9_ENVIRONMENT_ID --managed-credentials-action DISABLE &> /dev/null || true" > ~/.bashrc.d/c9.bash
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

cat << EOT > ~/.bashrc.d/aws.bash
export AWS_PAGER=""
export AWS_REGION="${AWS_REGION}"
export AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
export EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME}"
export EKS_DEFAULT_MNG_NAME="default"
export EKS_DEFAULT_MNG_MIN=3
export EKS_DEFAULT_MNG_MAX=6
export EKS_DEFAULT_MNG_DESIRED=3
EOT

touch ~/.bashrc.d/workshop-env.bash

cat << EOT > /home/ec2-user/.bashrc.d/aliases.bash
function prepare-environment() { 
  bash /usr/local/bin/reset-environment \$1
  exit_code=\$?
  source ~/.bashrc.d/workshop-env.bash
  return \$exit_code
}

function use-cluster() { bash /usr/local/bin/use-cluster \$1; source ~/.bashrc.d/env.bash; }
function create-cluster() { URL=https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/refs/heads/${REPOSITORY_REF}/cluster/eksctl/cluster.yaml; echo "Creating cluster with eksctl from $URL"; curl -fsSL $URL | envsubst | eksctl create cluster -f -; }
EOT

REPOSITORY_OWNER=${REPOSITORY_OWNER:-"aws-samples"}
REPOSITORY_NAME=${REPOSITORY_NAME:-"eks-workshop-v2"}

if [ ! -z "$REPOSITORY_REF" ]; then
  cat << EOT > ~/.bashrc.d/repository.bash
export REPOSITORY_OWNER='${REPOSITORY_OWNER}'
export REPOSITORY_NAME='${REPOSITORY_NAME}'
export REPOSITORY_REF='${REPOSITORY_REF}'
EOT
fi

RESOURCES_PRECREATED=${RESOURCES_PRECREATED:-"false"}

echo "export RESOURCES_PRECREATED='${RESOURCES_PRECREATED}'" > ~/.bashrc.d/infra.bash

echo "export ANALYTICS_ENDPOINT='${ANALYTICS_ENDPOINT}'" > ~/.bashrc.d/analytics.bash

/usr/local/bin/kubectl completion bash >  ~/.bashrc.d/kubectl_completion.bash
echo "alias k=kubectl" >> ~/.bashrc.d/kubectl_completion.bash
echo "complete -F __start_kubectl k" >> ~/.bashrc.d/kubectl_completion.bash

cat << EOT > /home/ec2-user/.banner-text

                                          Welcome to

███████╗██╗  ██╗███████╗    ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗██╗  ██╗ ██████╗ ██████╗ 
██╔════╝██║ ██╔╝██╔════╝    ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██║  ██║██╔═══██╗██╔══██╗
█████╗  █████╔╝ ███████╗    ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ ███████╗███████║██║   ██║██████╔╝
██╔══╝  ██╔═██╗ ╚════██║    ██║███╗██║██║   ██║██╔══██╗██╔═██╗ ╚════██║██╔══██║██║   ██║██╔═══╝ 
███████╗██║  ██╗███████║    ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████║██║  ██║╚██████╔╝██║     
╚══════╝╚═╝  ╚═╝╚══════╝     ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝ 

                      Hands-on labs for Amazon Elastic Kubernetes Service

EOT