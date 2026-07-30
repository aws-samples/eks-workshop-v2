output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CARTS_DYNAMODB_TABLENAME = aws_dynamodb_table.carts.name
    CARTS_IAM_ROLE           = module.iam_assumable_role_carts.iam_role_arn
  }
}