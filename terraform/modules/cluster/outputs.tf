output "eks_cluster_id" {
  description = "Amazon EKS Cluster Name"
  value       = module.aws-eks-accelerator-for-terraform.eks_cluster_id
}

output "eks_cluster_arn" {
  description = "Amazon EKS Cluster ARN"
  value       = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:cluster/${module.aws-eks-accelerator-for-terraform.eks_cluster_id}"
}

output "eks_cluster_nodegroup" {
  description = "Amazon EKS Cluster noode group ARN"
  value       = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:nodegroup/${module.aws-eks-accelerator-for-terraform.eks_cluster_id}"
}

output "eks_cluster_nodegroup_name" {
  description = "Amazon EKS Cluster node group name"
  value       = module.aws-eks-accelerator-for-terraform.managed_node_groups_id[0]
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
  value       = module.aws-eks-accelerator-for-terraform.configure_kubectl
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