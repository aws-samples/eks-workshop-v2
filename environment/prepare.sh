#!/bin/bash

set -e

if [ ! -z "$EKS_CLUSTER_NAME" ]; then
  aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
fi

mkdir -p ~/.ssh
aws ssm get-parameter --name ${GITOPS_SSH_SSM_NAME} --with-decryption \
  --query 'Parameter.Value' \
  --output text > ~/.ssh/gitops_ssh.pem

chmod 400 ~/.ssh/gitops_ssh.pem

cat << EOT > ~/.ssh/config
Host git-codecommit.*.amazonaws.com
  User ${GITOPS_IAM_SSH_USER}
  IdentityFile ~/.ssh/gitops_ssh.pem
EOT

chmod 600 ~/.ssh/config

echo "Generating SSH keys..."
ssh-keyscan -H git-codecommit.${AWS_DEFAULT_REGION}.amazonaws.com >> ~/.ssh/known_hosts

git config --global user.email "you@eksworkshop.com"
git config --global user.name "Your Name"
