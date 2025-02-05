output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    FSXN_SECRET_ARN     = data.aws_secretsmanager_secret.fsxn_password_secret.arn
    CLOUD_PROVIDER      = "AWS"
    CLOUD_IDENTITY      = "'\"'eks.amazonaws.com/role-arn: ${module.iam_iam-role-for-service-accounts-eks.iam_role_arn}'\"'"
  }
}