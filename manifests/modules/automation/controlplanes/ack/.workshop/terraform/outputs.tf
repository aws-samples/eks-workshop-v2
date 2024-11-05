output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CARTS_IAM_ROLE = module.iam_assumable_role_carts.iam_role_arn,
    DYNAMODB_POLICY_ARN = aws_iam_policy.carts_dynamo.arn
  }
}