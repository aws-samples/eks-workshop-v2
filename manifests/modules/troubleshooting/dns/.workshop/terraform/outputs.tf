output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    EKS_CLUSTER_NAME = var.addon_context.eks_cluster_id
  }
}
