output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CLOUD_PROVIDER      = "AWS"
    CLOUD_IDENTITY      = "'\"'eks.amazonaws.com/role-arn: ${module.iam_iam-role-for-service-accounts-eks.iam_role_arn}'\"'"
  }
}