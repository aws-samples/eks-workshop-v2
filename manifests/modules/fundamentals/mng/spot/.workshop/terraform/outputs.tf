output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = merge({
    SPOT_NODE_ROLE = aws_iam_role.spot_node.arn
    }, {
    for index, id in data.aws_subnets.private.ids : "PRIMARY_SUBNET_${index + 1}" => id
  })
}