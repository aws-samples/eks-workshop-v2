output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    FSXN_ID             = module.preprovision[0].fsxn_fs_id
    FSXN_SECRET         = module.preprovision[0].secret_arn
    SVM_NAME            = module.preprovision[0].fsxn_svm_name
    CLOUD_PROVIDER      = "AWS"
    CLOUD_IDENTITY      = "'\"'eks.amazonaws.com/role-arn: ${module.iam_iam-role-for-service-accounts-eks.iam_role_arn}'\"'"
  }
}