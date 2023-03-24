#!/bin/bash

set -e

if [[ ! -d "~/.bashrc.d" ]]; then
  mkdir -p ~/.bashrc.d
  
  touch ~/.bashrc.d/dummy.bash

  echo 'for file in ~/.bashrc.d/*.bash; do source "$file"; done' >> ~/.bashrc
fi

#echo 'aws cloud9 update-environment --environment-id $CLOUD9_ENVIRONMENT_ID --managed-credentials-action DISABLE &> /dev/null || true' > ~/.bashrc.d/c9.bash

echo 'export AWS_PAGER=""' > ~/.bashrc.d/aws.bash

#echo 'aws eks update-kubeconfig --name ${module.cluster.eks_cluster_id} > /dev/null' > ~/.bashrc.d/kubeconfig.bash

touch ~/.bashrc.d/workshop-env.bash

cat << EOT > /home/ec2-user/.bashrc.d/aliases.bash
function prepare-environment() { bash /usr/local/bin/reset-environment \$1; source ~/.bashrc.d/workshop-env.bash; }
EOT
