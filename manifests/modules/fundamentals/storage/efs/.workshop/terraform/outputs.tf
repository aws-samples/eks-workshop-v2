output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    EFS_CSI_ADDON_ROLE = module.efs_csi_driver_irsa.iam_role_arn
  }
}