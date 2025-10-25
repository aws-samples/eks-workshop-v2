output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = merge({
    FARGATE_IAM_PROFILE_ARN = aws_iam_role.fargate.arn
    }, {
    for index, id in data.aws_subnets.private.ids : "PRIVATE_SUBNET_${index + 1}" => id
  })
}