output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    ADOT_IAM_ROLE_CI = module.iam_assumable_role_adot_ci.iam_role_arn
  }
}