output "eks_cluster_id" {
  description = "Amazon EKS Cluster Name"
  value       = module.cluster.eks_cluster_id
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.cluster.configure_kubectl
}