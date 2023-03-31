#!/bin/bash

set -e

if [[ ! -d "~/.bashrc.d" ]]; then
  mkdir -p ~/.bashrc.d
  
  touch ~/.bashrc.d/dummy.bash

  echo 'for file in ~/.bashrc.d/*.bash; do source "$file"; done' >> ~/.bashrc
fi

if [ ! -z "$CLOUD9_ENVIRONMENT_ID" ]; then
  echo 'aws cloud9 update-environment --environment-id $CLOUD9_ENVIRONMENT_ID --managed-credentials-action DISABLE &> /dev/null || true' > ~/.bashrc.d/c9.bash
fi

echo 'export AWS_PAGER=""' > ~/.bashrc.d/aws.bash

touch ~/.bashrc.d/workshop-env.bash

cat << EOT > /home/ec2-user/.bashrc.d/aliases.bash
function prepare-environment() { bash /usr/local/bin/reset-environment \$1; source ~/.bashrc.d/workshop-env.bash; }
EOT

if [ ! -z "$REPOSITORY_REF" ]; then
  cat << EOT > /usr/local/bin/reset-environment
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/\$REPOSITORY_REF/lab/bin/reset-environment | bash
EOT
  chmod +x /usr/local/bin/reset-environment
  cat << EOT > /usr/local/bin/delete-environment
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/\$MANIFESTS_REF/lab/bin/delete-environment | bash
EOT
  chmod +x /usr/local/bin/delete-environment
  cat << EOT > /usr/local/bin/wait-for-lb
#!/bin/bash
set -e
curl -fsSL https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/\$MANIFESTS_REF/lab/bin/wait-for-lb | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/wait-for-lb
fi