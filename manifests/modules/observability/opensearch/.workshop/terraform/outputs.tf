output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    LAMBDA_ARN      = aws_lambda_function.eks_control_plane_logs_to_opensearch.arn
    LAMBDA_ROLE_ARN = aws_iam_role.lambda_execution_role.arn
  }
}