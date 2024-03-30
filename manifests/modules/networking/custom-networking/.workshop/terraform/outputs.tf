output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = merge({
    VPC_ID                        = data.aws_vpc.selected.id
    EKS_CLUSTER_SECURITY_GROUP_ID = var.cluster_security_group_id
    CUSTOM_NETWORKING_NODE_ROLE   = aws_iam_role.custom_networking_node.arn
    }, {
    for index, id in data.aws_subnets.private.ids : "PRIMARY_SUBNET_${index + 1}" => id
    }, {
    for index, cidr in aws_subnet.in_secondary_cidr : "SECONDARY_SUBNET_${index + 1}" => cidr.id
    }, {
    for index, cidr in aws_subnet.in_secondary_cidr : "SUBNET_AZ_${index + 1}" => cidr.availability_zone
  })
}