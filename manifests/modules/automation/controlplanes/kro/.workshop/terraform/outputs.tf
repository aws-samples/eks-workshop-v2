output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    ACCOUNT_ID = data.aws_caller_identity.current.account_id
  }
}