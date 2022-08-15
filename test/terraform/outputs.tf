output "eks_cluster_id" {
  value       = module.local.eks_cluster_id
}

output "iam_role_arn" {
  value       = module.local.iam_role_arn
}

output "environment_variables" {
  value = module.local.environment_variables
}