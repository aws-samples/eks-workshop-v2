output "eks_cluster_id" {
  description = "Amazon EKS Cluster Name"
  value       = module.eks_blueprints.eks_cluster_id
}

output "eks_cluster_arn" {
  description = "Amazon EKS Cluster ARN"
  value       = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks_blueprints.eks_cluster_id}"
}

output "eks_cluster_nodegroup" {
  description = "Amazon EKS Cluster noode group ARN"
  value       = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:nodegroup/${module.eks_blueprints.eks_cluster_id}"
}

output "eks_cluster_nodegroup_name" {
  description = "Amazon EKS Cluster node group name"
  value       = module.eks_blueprints.managed_node_groups_id[0]
}

output "eks_cluster_tainted_nodegroup_name" {
  description = "Amazon EKS Cluster tainted node group name"
  value       = module.eks_blueprints.managed_node_groups_id[1]
}

output "eks_cluster_nodegroup_size_min" {
  description = "Amazon EKS Cluster node group min size"
  value       = local.default_mng_min
}

output "eks_cluster_nodegroup_size_max" {
  description = "Amazon EKS Cluster node group max size"
  value       = local.default_mng_max
}

output "eks_cluster_nodegroup_size_desired" {
  description = "Amazon EKS Cluster node group desired size"
  value       = local.default_mng_size
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.eks_blueprints.configure_kubectl
}

output "vpc_id" {
  description = "VPC Id"
  value       = module.aws_vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = module.aws_vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private Subnet Ids"
  value       = module.aws_vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public Subnet Ids"
  value       = module.aws_vpc.public_subnets
}

output "blueprints_addons" {
  description = "Information about EKS blueprints addons installed"
  value = {
    "descheduler" = {
      helm_release = module.descheduler.helm_release
      link         = "https://github.com/aws-samples/eks-workshop-v2/tree/main/terraform/modules/addons/descheduler"
    }
  }
}

output "cart_dynamodb_table_name" {
  description = "Name of the DynamoDB table created for the cart service"
  value       = aws_dynamodb_table.carts.name
}

output "cart_iam_role" {
  description = "ARN of the IAM role to allow access to DynamoDB for the cart service"
  value       = module.iam_assumable_role_carts.iam_role_arn
}

output "catalog_rds_endpoint" {
  description = "Endpoint of the RDS database for the catalog service"
  value       = module.catalog_mysql.db_instance_endpoint
}

output "catalog_rds_master_username" {
  description = "Master username of the RDS database for the catalog service"
  value       = "catalog_user"
}

output "catalog_rds_master_password" {
  description = "Master password of the RDS database for the catalog service"
  value       = random_string.catalog_db_master.result
}

output "catalog_rds_database_name" {
  description = "Database name associated with the RDS database for the catalog service"
  value       = "catalog"
}

output "catalog_rds_sg_id" {
  description = "Security group applied to the catalog RDS database"
  value       = module.catalog_rds_ingress.security_group_id
}

output "catalog_sg_id" {
  description = "Security group for clients to access the catalog RDS database"
  value       = aws_security_group.catalog_rds_ingress.id
}

output "aiml_neuron_s3_bucket_name" {
  description = "Name of the S3 bucket created for the AI/ML"
  value       = aws_s3_bucket.inference.id
}

output "aiml_neuron_role_arn" {
  description = "Arn of role for neuron workloads for the AI/ML"
  value       = module.iam_assumable_role_inference.iam_role_arn
}

output "efsid" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.efsassets.id
}

output "amp_endpoint" {
  description = "Endpoint of the AMP workspace"
  value       = aws_prometheus_workspace.this.prometheus_endpoint
}

output "adot_iam_role" {
  description = "ARN of the IAM role used by the ADOT collector pod"
  value       = module.iam_assumable_role_adot.iam_role_arn
}
output "azs" {
  description = "List of availability zones used"
  value       = local.azs
}

output "adot_iam_role_ci" {
  description = "ARN of the IAM role used by the ADOT collector pod for Container Insights"
  value       = module.iam_assumable_role_adot_ci.iam_role_arn
}

output "eks_cluster_security_group_id" {
  description = "EKS Control Plane Security Group ID"
  value       = module.eks_blueprints.cluster_primary_security_group_id
}


output "eks_cluster_managed_node_group_iam_role_arns" {
  description = "IAM role arn's of managed node groups"
  value       = module.eks_blueprints.managed_node_group_iam_role_arns
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = module.eks_blueprints.oidc_provider
}

output "gitops_ssh_iam_user" {
  value       = aws_iam_user.gitops.unique_id
  description = "ID of the IAM user for GitOps"
}

output "gitops_ssh_ssm_name" {
  value       = aws_ssm_parameter.gitops.name
  description = "Name of the SSM parameter used to store the GitOps private key"
}

output "gitops_iam_ssh_key_id" {
  value       = aws_iam_user_ssh_key.gitops.id
  description = "ID of the IAM SSH key for GitOps"
}
