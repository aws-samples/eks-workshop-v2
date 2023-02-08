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
  description = "Environment variables that will be injected in to the participants shell (Cloud9 etc)"
  value       = local.environment_variables
  sensitive   = true
}

output "blueprints_addons" {
  sensitive   = true
  value       = module.cluster.blueprints_addons
  description = "Information about EKS blueprints addons installed"
}
