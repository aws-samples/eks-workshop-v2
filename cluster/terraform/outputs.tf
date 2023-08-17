output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${data.aws_region.current.id} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "eks" {
  description = "Amazon EKS module"
  value       = module.eks
}

output "vpc" {
  description = "Amazon VPC module"
  value       = module.vpc
}
