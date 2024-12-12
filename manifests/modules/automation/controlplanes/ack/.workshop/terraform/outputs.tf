output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CARTS_IAM_ROLE      = module.iam_assumable_role_carts.iam_role_arn,
    DYNAMODB_POLICY_ARN = aws_iam_policy.ack_dynamo.arn
    ACK_IAM_ROLE        = module.iam_assumable_role_ack.iam_role_arn,
    DYNAMO_ACK_VERSION  = var.dynamo_ack_version
  }
}