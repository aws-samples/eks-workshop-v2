output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CATALOG_IAM_ROLE = module.secrets_manager_role.iam_role_arn
  }
}