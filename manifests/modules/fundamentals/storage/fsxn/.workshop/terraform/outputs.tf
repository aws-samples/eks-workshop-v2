output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    FSXN_ID             = module.preprovision.fsxn_fs_id
    FSXN_SECRET         = module.preprovision.secret_arn
    SVM_NAME            = module.preprovision.fsxn_svm_name
  }
}