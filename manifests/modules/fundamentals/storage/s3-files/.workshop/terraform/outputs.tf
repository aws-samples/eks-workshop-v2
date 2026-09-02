output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    S3_FILES_CSI_ADDON_ROLE = module.s3_files_csi_driver_irsa.iam_role_arn
    S3_FILES_ID             = try(module.preprovision[0].s3_file_system_id, "")
    S3_FILES_BUCKET_NAME    = try(module.preprovision[0].s3_bucket_name, "")
  }
}
