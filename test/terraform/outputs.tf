output "eks_cluster_id" {
  description = "Identifier for the cluster"
  value       = module.core.eks_cluster_id
}

output "iam_role_arn" {
  description = "IAM role ARN created for local shell"
  value       = module.core.iam_role_arn
}

output "environment_variables" {
  description = "Environment variables that will be injected in to the shell"
  value       = module.core.environment_variables
  sensitive   = true
}
