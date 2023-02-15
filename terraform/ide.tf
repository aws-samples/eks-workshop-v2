locals {
  environment_variables = <<EOT
AWS_ACCOUNT_ID=${data.aws_caller_identity.current.account_id}
AWS_DEFAULT_REGION=${data.aws_region.current.name}
EKS_CLUSTER_NAME=${try(module.cluster.eks_cluster_id, "")}
EKS_DEFAULT_MNG_NAME=${try(split(":", module.cluster.eks_cluster_nodegroup_name)[1], "")}
EKS_DEFAULT_MNG_MIN=${module.cluster.eks_cluster_nodegroup_size_min}
EKS_DEFAULT_MNG_MAX=${module.cluster.eks_cluster_nodegroup_size_max}
EKS_DEFAULT_MNG_DESIRED=${module.cluster.eks_cluster_nodegroup_size_desired}
CARTS_DYNAMODB_TABLENAME=${module.cluster.cart_dynamodb_table_name}
CARTS_IAM_ROLE=${try(module.cluster.cart_iam_role, "")}
CATALOG_RDS_ENDPOINT=${module.cluster.catalog_rds_endpoint}
CATALOG_RDS_USERNAME=${module.cluster.catalog_rds_master_username}
CATALOG_RDS_PASSWORD=${base64encode(module.cluster.catalog_rds_master_password)}
CATALOG_RDS_DATABASE_NAME=${module.cluster.catalog_rds_database_name}
CATALOG_RDS_SG_ID=${module.cluster.catalog_rds_sg_id}
CATALOG_SG_ID=${module.cluster.catalog_sg_id}
EFS_ID=${module.cluster.efsid}
EKS_TAINTED_MNG_NAME=${try(split(":", module.cluster.eks_cluster_tainted_nodegroup_name)[1], "")}
AMP_ENDPOINT=${module.cluster.amp_endpoint}
ADOT_IAM_ROLE=${try(module.cluster.adot_iam_role, "")}
VPC_ID=${module.cluster.vpc_id}
EKS_CLUSTER_SECURITY_GROUP_ID=${try(module.cluster.eks_cluster_security_group_id, "")}
PRIMARY_SUBNET_1=${module.cluster.private_subnet_ids[0]}
PRIMARY_SUBNET_2=${module.cluster.private_subnet_ids[1]}
PRIMARY_SUBNET_3=${module.cluster.private_subnet_ids[2]}
SECONDARY_SUBNET_1=${module.cluster.private_subnet_ids[3]}
SECONDARY_SUBNET_2=${module.cluster.private_subnet_ids[4]}
SECONDARY_SUBNET_3=${module.cluster.private_subnet_ids[5]}
MANAGED_NODE_GROUP_IAM_ROLE_ARN=${try(module.cluster.eks_cluster_managed_node_group_iam_role_arns[0], "")}
AZ1=${module.cluster.azs[0]}
AZ2=${module.cluster.azs[1]}
AZ3=${module.cluster.azs[2]}
ADOT_IAM_ROLE_CI=${try(module.cluster.adot_iam_role_ci, "")}
OIDC_PROVIDER=${try(module.cluster.oidc_provider, "")}
VPC_ID=${module.cluster.vpc_id}
VPC_CIDR=${module.cluster.vpc_cidr}
VPC_PRIVATE_SUBNET_ID_0=${module.cluster.private_subnet_ids[0]}
VPC_PRIVATE_SUBNET_ID_1=${module.cluster.private_subnet_ids[1]}
VPC_PRIVATE_SUBNET_ID_2=${module.cluster.private_subnet_ids[2]}
GITOPS_IAM_SSH_KEY_ID=${try(module.cluster.gitops_iam_ssh_key_id, "")}
GITOPS_IAM_SSH_USER=${module.cluster.gitops_ssh_iam_user}
GITOPS_SSH_SSM_NAME=${module.cluster.gitops_ssh_ssm_name}
MANIFESTS_REF=${var.repository_ref}
EOT

  bootstrap_script = <<EOF
set -e
curl -fsSL https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/${var.repository_ref}/environment/installer.sh | bash

bash -c "aws cloud9 update-environment --environment-id $CLOUD9_ENVIRONMENT_ID --managed-credentials-action DISABLE || true"

cat << EOT > /usr/local/bin/reset-environment
#!/bin/bash

set -e
curl -fsSL https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/\$MANIFESTS_REF/environment/bin/reset-environment | bash
EOT

chmod +x /usr/local/bin/reset-environment

cat << EOT > /usr/local/bin/delete-environment
#!/bin/bash

set -e
curl -fsSL https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/\$MANIFESTS_REF/environment/bin/delete-environment | bash
EOT

chmod +x /usr/local/bin/delete-environment

cat << EOT > /usr/local/bin/wait-for-lb
#!/bin/bash

set -e
curl -fsSL https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/\$MANIFESTS_REF/environment/bin/wait-for-lb | bash
EOT

chmod +x /usr/local/bin/wait-for-lb

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
