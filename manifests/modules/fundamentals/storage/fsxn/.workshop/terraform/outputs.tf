output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    FSXN_ID             = module.preprovision[0].fsxn_fs_id
    FSXN_SECRET         = module.preprovision[0].secret_arn
    SVM_NAME            = module.preprovision[0].fsxn_svm_name
  }
}