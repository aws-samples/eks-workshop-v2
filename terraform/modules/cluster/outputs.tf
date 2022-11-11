output "eks_cluster_id" {
  description = "Amazon EKS Cluster Name"
  value       = module.eks-blueprints.eks_cluster_id
}

output "eks_cluster_arn" {
  description = "Amazon EKS Cluster ARN"
  value       = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks-blueprints.eks_cluster_id}"
}

output "eks_cluster_nodegroup" {
  description = "Amazon EKS Cluster noode group ARN"
  value       = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:nodegroup/${module.eks-blueprints.eks_cluster_id}"
}

output "eks_cluster_nodegroup_name" {
  description = "Amazon EKS Cluster node group name"
  value       = module.eks-blueprints.managed_node_groups_id[0]
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
  value       = module.eks-blueprints.configure_kubectl
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

output "orders_rds_endpoint" {
  description = "Endpoint of the RDS database for the orders service"
  value       = module.orders_rds.cluster_endpoint
}

output "orders_rds_master_username" {
  description = "Master username of the RDS database for the orders service"
  value       = "orders"
}

output "orders_rds_master_password" {
  description = "Master password of the RDS database for the orders service"
  value       = random_string.orders_db_master.result
}

output "orders_rds_database_name" {
  description = "Master username of the RDS database for the orders service"
  value       = module.orders_rds.cluster_database_name
}

output "orders_rds_ingress_sg_id" {
  description = "Endpoint of the RDS database for the orders service"
  value       = aws_security_group.orders_rds_ingress.id
}

output "efsid" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.efsassets.id
}

output "networking_rds_endpoint" {
  description = "Endpoint of the RDS database for the networking module"
  value       = module.networking_rds_postgre.cluster_endpoint
}

output "networking_rds_master_username" {
  description = "Master username of the RDS database for the networking module"
  value       = "eksworkshop"
}

output "networking_rds_master_password" {
  description = "Master password of the RDS database for the networking module"
  value       = random_string.networking_db_master.result
}

output "networking_rds_database_name" {
  description = "Master username of the RDS database for the networking module"
  value       = module.networking_rds_postgre.cluster_database_name
}

output "networking_rds_ingress_sg_id" {
  description = "Security group id of the RDS database for the networking module"
  value       = module.networking_rds_postgre.security_group_id
}

output "amp_endpoint" {
  description = "Endpoint of the AMP workspace"
  value       = aws_prometheus_workspace.this.prometheus_endpoint
}

output "adot_iam_role" {
  description = "ARN of the IAM role used by the ADOT collector pod"
  value       = module.iam_assumable_role_adot.iam_role_arn
}
output "adot_iam_role_ci" {
  description = "ARN of the IAM role used by the ADOT collector pod for Container Insights"
  value       = module.iam_assumable_role_adot_ci.iam_role_arn
}


output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = module.eks-blueprints.oidc_provider
}

output "vpc_id" {
  description = "The VPC ID"
  value       = module.aws_vpc.vpc_id
}

