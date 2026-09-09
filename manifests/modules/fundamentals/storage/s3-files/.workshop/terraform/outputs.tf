output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    S3_FILES_CSI_ADDON_ROLE = module.s3_files_csi_driver_irsa.iam_role_arn
  }
}
