locals {
  environment_variables = <<EOT
AWS_ACCOUNT_ID=${data.aws_caller_identity.current.account_id}
AWS_DEFAULT_REGION=${data.aws_region.current.name}
EKS_CLUSTER_NAME=${try(module.cluster.eks_cluster_id, "")}
EKS_DEFAULT_MNG_NAME=${try(split(":", module.cluster.eks_cluster_nodegroup_name)[1], "")}
EKS_DEFAULT_MNG_MIN=${module.cluster.eks_cluster_nodegroup_size_min}
EKS_DEFAULT_MNG_MAX=${module.cluster.eks_cluster_nodegroup_size_max}
EKS_DEFAULT_MNG_DESIRED=${module.cluster.eks_cluster_nodegroup_size_desired}
CARTS_DYNAMODB_TABLENAME=${try(module.cluster.cart_dynamodb_table_name, "")}
CARTS_IAM_ROLE=${try(module.cluster.cart_iam_role, "")}
CATALOG_RDS_ENDPOINT=${try(module.cluster.catalog_rds_endpoint, "")}
CATALOG_RDS_USERNAME=${try(module.cluster.catalog_rds_master_username, "")}
CATALOG_RDS_PASSWORD=${try(base64encode(module.cluster.catalog_rds_master_password), "")}
CATALOG_RDS_DATABASE_NAME=${try(module.cluster.catalog_rds_database_name, "")}
CATALOG_RDS_SG_ID=${try(module.cluster.catalog_rds_sg_id, "")}
CATALOG_SG_ID=${try(module.cluster.catalog_sg_id, "")}
EFS_ID=${try(module.cluster.efsid, "")}
EKS_TAINTED_MNG_NAME=${try(split(":", module.cluster.eks_cluster_tainted_nodegroup_name)[1], "")}
AMP_ENDPOINT=${try(module.cluster.amp_endpoint, "")}
ADOT_IAM_ROLE=${try(module.cluster.adot_iam_role, "")}
VPC_ID=${try(module.cluster.vpc_id, "")}
EKS_CLUSTER_SECURITY_GROUP_ID=${try(module.cluster.eks_cluster_security_group_id, "")}
PRIMARY_SUBNET_1=${try(module.cluster.private_subnet_ids[0], "")}
PRIMARY_SUBNET_2=${try(module.cluster.private_subnet_ids[1], "")}
PRIMARY_SUBNET_3=${try(module.cluster.private_subnet_ids[2], "")}
SECONDARY_SUBNET_1=${try(module.cluster.private_subnet_ids[3], "")}
SECONDARY_SUBNET_2=${try(module.cluster.private_subnet_ids[4], "")}
SECONDARY_SUBNET_3=${try(module.cluster.private_subnet_ids[5], "")}
MANAGED_NODE_GROUP_IAM_ROLE_ARN=${try(module.cluster.eks_cluster_managed_node_group_iam_role_arns[0], "")}
AZ1=${module.cluster.azs[0]}
AZ2=${module.cluster.azs[1]}
AZ3=${module.cluster.azs[2]}
ADOT_IAM_ROLE_CI=${try(module.cluster.adot_iam_role_ci, "")}
OIDC_PROVIDER=${try(module.cluster.oidc_provider, "")}
VPC_ID=${try(module.cluster.vpc_id, "")}
VPC_CIDR=${try(module.cluster.vpc_cidr, "")}
VPC_PRIVATE_SUBNET_ID_0=${try(module.cluster.private_subnet_ids[0], "")}
VPC_PRIVATE_SUBNET_ID_1=${try(module.cluster.private_subnet_ids[1], "")}
VPC_PRIVATE_SUBNET_ID_2=${try(module.cluster.private_subnet_ids[2], "")}
GITOPS_IAM_SSH_KEY_ID=${try(module.cluster.gitops_iam_ssh_key_id, "")}
GITOPS_IAM_SSH_USER=${try(module.cluster.gitops_ssh_iam_user, "")}
GITOPS_SSH_SSM_NAME=${try(module.cluster.gitops_ssh_ssm_name, "")}
EOT

  bootstrap_script = <<EOF
set -e

rm -rf /tmp/workshop-repository
git clone https://github.com/aws-samples/eks-workshop-v2 /tmp/workshop-repository
(cd /tmp/workshop-repository && git checkout ${var.repository_ref})

(cd /tmp/workshop-repository/environment && bash ./installer.sh)

bash -c "aws cloud9 update-environment --environment-id $CLOUD9_ENVIRONMENT_ID --managed-credentials-action DISABLE || true"

mkdir -p /workspace
cp -R /tmp/workshop-repository/environment/workspace/* /workspace
cp -R /workspace /workspace-backup
chown ec2-user -R /workspace
chmod +x /tmp/workshop-repository/environment/bin/*
cp /tmp/workshop-repository/environment/bin/* /usr/local/bin

rm -rf /tmp/workshop-repository

sudo -H -u ec2-user bash -c "ln -sf /workspace ~/environment/workspace"

if [[ ! -d "/home/ec2-user/.bashrc.d" ]]; then
  sudo -H -u ec2-user bash -c "mkdir -p ~/.bashrc.d"
  sudo -H -u ec2-user bash -c "touch ~/.bashrc.d/dummy.bash"

  sudo -H -u ec2-user bash -c "echo 'for file in ~/.bashrc.d/*.bash; do source \"\$file\"; done' >> ~/.bashrc"
fi

sudo -H -u ec2-user bash -c "echo 'aws cloud9 update-environment --environment-id $CLOUD9_ENVIRONMENT_ID --managed-credentials-action DISABLE &> /dev/null || true' > ~/.bashrc.d/c9.bash"

sudo -H -u ec2-user bash -c "echo 'export AWS_PAGER=\"\"' > ~/.bashrc.d/aws.bash"

sudo -H -u ec2-user bash -c "echo 'aws eks update-kubeconfig --name ${module.cluster.eks_cluster_id} > /dev/null' > ~/.bashrc.d/kubeconfig.bash"

cat << EOT > /home/ec2-user/.bashrc.d/env.bash
set -a
${local.environment_variables}
set +a
EOT

chown ec2-user /home/ec2-user/.bashrc.d/env.bash

sudo rm -f /home/ec2-user/.ssh/gitops_ssh.pem

sudo -H -u ec2-user bash -c "aws ssm get-parameter --name ${module.cluster.gitops_ssh_ssm_name} --with-decryption --query 'Parameter.Value' --region ${data.aws_region.current.name} --output text > ~/.ssh/gitops_ssh.pem"
chmod 400 /home/ec2-user/.ssh/gitops_ssh.pem

cat << EOT > /home/ec2-user/.ssh/config
Host git-codecommit.*.amazonaws.com
  User ${module.cluster.gitops_ssh_iam_user}
  IdentityFile ~/.ssh/gitops_ssh.pem
EOT
chown ec2-user /home/ec2-user/.ssh/config
chmod 600 /home/ec2-user/.ssh/config

sudo -H -u ec2-user bash -c "ssh-keyscan -H git-codecommit.${data.aws_region.current.name}.amazonaws.com >> ~/.ssh/known_hosts"

sudo -H -u ec2-user bash -c 'git config --global user.email "you@eksworkshop.com"'
sudo -H -u ec2-user bash -c 'git config --global user.name "EKS Workshop Learner"'
EOF
}

module "ide" {
  source = "./modules/ide"

  environment_name = module.cluster.eks_cluster_id
  subnet_id        = module.cluster.public_subnet_ids[0]
  cloud9_owner     = var.cloud9_owner

  additional_cloud9_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  additional_cloud9_policies = [
    jsondecode(templatefile("${path.module}/templates/iam_policy.json", {
      cluster_name = module.cluster.eks_cluster_id,
      cluster_arn  = module.cluster.eks_cluster_arn,
      nodegroup    = module.cluster.eks_cluster_nodegroup
      region       = data.aws_region.current.name
      account_id   = data.aws_caller_identity.current.account_id
    }))
  ]

  bootstrap_script = local.bootstrap_script
}
