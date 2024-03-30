output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = merge({
    GRAVITON_NODE_ROLE = aws_iam_role.graviton_node.arn
    }, {
    for index, id in data.aws_subnets.private.ids : "PRIMARY_SUBNET_${index + 1}" => id
  })
}