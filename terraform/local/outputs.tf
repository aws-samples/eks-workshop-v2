output "eks_cluster_id" {
  description = "Amazon EKS Cluster Name"
  value       = module.cluster.eks_cluster_id
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.cluster.configure_kubectl
}

output "iam_role_arn" {
  description = "ARN of the IAM role to be used for local testing"
  value       = aws_iam_role.local_role.arn
}

output "environment_variables" {
  value = <<EOT
AWS_ACCOUNT_ID=${data.aws_caller_identity.current.account_id}
EKS_CLUSTER_NAME=${module.cluster.eks_cluster_id}
EKS_DEFAULT_MNG_NAME=${split(":", module.cluster.eks_cluster_nodegroup_name)[1]}
EKS_DEFAULT_MNG_MIN=${module.cluster.eks_cluster_nodegroup_size_min}
EKS_DEFAULT_MNG_MAX=${module.cluster.eks_cluster_nodegroup_size_max}
EKS_DEFAULT_MNG_DESIRED=${module.cluster.eks_cluster_nodegroup_size_desired}
CARTS_DYNAMODB_TABLENAME=${module.cluster.cart_dynamodb_table_name}
CARTS_IAM_ROLE=${module.cluster.cart_iam_role}
EOT
}