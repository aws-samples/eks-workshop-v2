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

cat << EOT > ~/.bashrc.d/aws.bash
export AWS_PAGER=""
export AWS_REGION="${AWS_REGION}"
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

/usr/local/bin/kubectl completion bash >>  ~/.bashrc.d/kubectl_completion.bash