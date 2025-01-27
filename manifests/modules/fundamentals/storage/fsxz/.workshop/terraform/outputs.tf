output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    FSXZ_CSI_ADDON_ROLE = module.fsxz_csi_driver_irsa.iam_role_arn
    EKS_CLUSTER_NAME  = var.eks_cluster_id
  }
}