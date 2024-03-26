output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    DYNAMODB_POLICY_ARN = aws_iam_policy.carts_dynamo.arn
  }
}