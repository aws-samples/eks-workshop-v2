output "eks_cluster_id" {
  description = "Amazon EKS Cluster Name"
  value       = module.cluster.eks_cluster_id
}