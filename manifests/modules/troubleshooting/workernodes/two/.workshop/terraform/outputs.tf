

# output "environment_variables" {
#   description = "Environment variables to be added to the IDE shell"
#   value = {
#     MY_ENVIRONMENT_VARIABLE         = "abc1234"
#     NEW_NODEGROUP_2_ASG_NAME        = aws_eks_node_group.new_nodegroup_2.resources[0].autoscaling_groups[0].name,
#     NEW_NODEGROUP_2_INSTANCE_ID = length(data.aws_instances.new_nodegroup_2_instances.ids) > 0 ? 
#       [for id in data.aws_instances.new_nodegroup_2_instances.ids : 
#         id if data.aws_instances.new_nodegroup_2_instances.instance_states[index(data.aws_instances.new_nodegroup_2_instances.ids, id)] == "running"
#       ][0] : "No running instances found",
#     NEW_NODEGROUP_2_SUBNET_ID       = aws_subnet.new_subnet.id,
#     NEW_NODEGROUP_2_ROUTETABLE_ID   = aws_route_table.new_route_table.id,
#     DEFAULT_NODEGROUP_NATGATEWAY_ID = length(data.aws_nat_gateways.cluster_nat_gateways.ids) > 0 ? data.aws_nat_gateways.cluster_nat_gateways.ids[0] : "No NAT Gateway found"
#   }
# }

output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    MY_ENVIRONMENT_VARIABLE  = "abc1234",
    NEW_NODEGROUP_2_ASG_NAME = aws_eks_node_group.new_nodegroup_2.resources[0].autoscaling_groups[0].name,
    NEW_NODEGROUP_2_INSTANCE_ID = length(data.aws_instances.new_nodegroup_2_instances.ids) > 0 ? (
      data.aws_instances.new_nodegroup_2_instances.ids[0]
    ) : "No running instances found",
    NEW_NODEGROUP_2_SUBNET_ID       = aws_subnet.new_subnet.id,
    NEW_NODEGROUP_2_ROUTETABLE_ID   = aws_route_table.new_route_table.id,
    DEFAULT_NODEGROUP_NATGATEWAY_ID = length(data.aws_nat_gateways.cluster_nat_gateways.ids) > 0 ? data.aws_nat_gateways.cluster_nat_gateways.ids[0] : "No NAT Gateway found"
  }
}


# output "environment_variables" {
#   description = "Environment variables to be added to the IDE shell"
#   value = {
#     MY_ENVIRONMENT_VARIABLE         = "abc1234",
#     NEW_NODEGROUP_2_ASG_NAME        = aws_eks_node_group.new_nodegroup_2.resources[0].autoscaling_groups[0].name,
#     NEW_NODEGROUP_2_INSTANCE_ID     = length(data.aws_instances.new_nodegroup_2_instances.ids) > 0 ? (
#       [for id in data.aws_instances.new_nodegroup_2_instances.ids : 
#         id if data.aws_instances.new_nodegroup_2_instances.instance_states[index(data.aws_instances.new_nodegroup_2_instances.ids, id)] == "running"
#       ][0]
#     ) : "No running instances found",
#     NEW_NODEGROUP_2_SUBNET_ID       = aws_subnet.new_subnet.id,
#     NEW_NODEGROUP_2_ROUTETABLE_ID   = aws_route_table.new_route_table.id,
#     DEFAULT_NODEGROUP_NATGATEWAY_ID = length(data.aws_nat_gateways.cluster_nat_gateways.ids) > 0 ? data.aws_nat_gateways.cluster_nat_gateways.ids[0] : "No NAT Gateway found"
#   }
# }
