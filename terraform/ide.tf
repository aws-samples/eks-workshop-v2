locals {
  environment_variables = <<EOT
AWS_ACCOUNT_ID=${data.aws_caller_identity.current.account_id}
AWS_DEFAULT_REGION=${data.aws_region.current.name}
EKS_CLUSTER_NAME=${module.cluster.eks_cluster_id}
EKS_DEFAULT_MNG_NAME=${split(":", module.cluster.eks_cluster_nodegroup_name)[1]}
EKS_DEFAULT_MNG_MIN=${module.cluster.eks_cluster_nodegroup_size_min}
EKS_DEFAULT_MNG_MAX=${module.cluster.eks_cluster_nodegroup_size_max}
EKS_DEFAULT_MNG_DESIRED=${module.cluster.eks_cluster_nodegroup_size_desired}
CARTS_DYNAMODB_TABLENAME=${module.cluster.cart_dynamodb_table_name}
CARTS_IAM_ROLE=${module.cluster.cart_iam_role}
CATALOG_RDS_ENDPOINT=${module.cluster.catalog_rds_endpoint}
CATALOG_RDS_USERNAME=${module.cluster.catalog_rds_master_username}
CATALOG_RDS_PASSWORD=${base64encode(module.cluster.catalog_rds_master_password)}
CATALOG_RDS_DATABASE_NAME=${module.cluster.catalog_rds_database_name}
CATALOG_RDS_SG_ID=${module.cluster.catalog_rds_sg_id}
CATALOG_SG_ID=${module.cluster.catalog_sg_id}
EFS_ID=${module.cluster.efsid}
EKS_TAINTED_MNG_NAME=${split(":", module.cluster.eks_cluster_tainted_nodegroup_name)[1]}
AMP_ENDPOINT=${module.cluster.amp_endpoint}
ADOT_IAM_ROLE=${module.cluster.adot_iam_role}
VPC_ID=${module.cluster.vpc_id}
EKS_CLUSTER_SECURITY_GROUP_ID=${module.cluster.eks_cluster_security_group_id}
PRIMARY_SUBNET_1=${module.cluster.private_subnet_ids[0]}
PRIMARY_SUBNET_2=${module.cluster.private_subnet_ids[1]}
PRIMARY_SUBNET_3=${module.cluster.private_subnet_ids[2]}
SECONDARY_SUBNET_1=${module.cluster.private_subnet_ids[3]}
SECONDARY_SUBNET_2=${module.cluster.private_subnet_ids[4]}
SECONDARY_SUBNET_3=${module.cluster.private_subnet_ids[5]}
MANAGED_NODE_GROUP_IAM_ROLE_ARN=${module.cluster.eks_cluster_managed_node_group_iam_role_arns[0]}
AZ1=${module.cluster.azs[0]}
AZ2=${module.cluster.azs[1]}
AZ3=${module.cluster.azs[2]}
ADOT_IAM_ROLE_CI=${module.cluster.adot_iam_role_ci}
OIDC_PROVIDER=${module.cluster.oidc_provider}
VPC_ID=${module.cluster.vpc_id}
VPC_PRIVATE_SUBNET_ID_0=${module.cluster.private_subnet_ids[0]}
VPC_PRIVATE_SUBNET_ID_1=${module.cluster.private_subnet_ids[1]}
VPC_PRIVATE_SUBNET_ID_2=${module.cluster.private_subnet_ids[2]}
EOT

  bootstrap_script = <<EOF
rm -rf /tmp/workshop-repository
git clone https://${var.github_token}@github.com/aws-samples/eks-workshop-v2 /tmp/workshop-repository
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
EOF
}

module "ide" {
  source = "./modules/ide"

  environment_name = module.cluster.eks_cluster_id
  subnet_id        = module.cluster.public_subnet_ids[0]
  cloud9_owner     = var.cloud9_owner

  additional_cloud9_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  additional_cloud9_policies = [
    jsondecode(templatefile("${path.module}/templates/iam_policy.json", {
      cluster_name = module.cluster.eks_cluster_id,
      cluster_arn  = module.cluster.eks_cluster_arn,
      nodegroup    = module.cluster.eks_cluster_nodegroup
      region       = data.aws_region.current.name
    }))
  ]

  bootstrap_script = var.github_token == "" ? "" : local.bootstrap_script
}
