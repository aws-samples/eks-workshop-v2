output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    EBS_CSI_ADDON_ROLE = module.ebs_csi_driver_irsa.iam_role_arn
  }
}