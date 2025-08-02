output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    # Common variables
    MY_ENVIRONMENT_VARIABLE = "abc1234",
    EKS_CLUSTER_NAME        = var.addon_context.eks_cluster_id,

    # Nodegroup 1 variables
    NEW_NODEGROUP_1_ASG_NAME = try(
      aws_eks_node_group.new_nodegroup_1.resources[0].autoscaling_groups[0].name,
      "not-found"
    ),
    NEW_NODEGROUP_1_LT_ID = aws_eks_node_group.new_nodegroup_1.launch_template[0].id,
    NEW_KMS_KEY_ID        = aws_kms_key.new_kms_key.id,

    # Nodegroup 2 variables
    NEW_NODEGROUP_2_ASG_NAME = try(
      aws_eks_node_group.new_nodegroup_2.resources[0].autoscaling_groups[0].name,
      "not-found"
    ),
    NEW_NODEGROUP_2_INSTANCE_ID = try(
      data.aws_instances.new_nodegroup_2_instances.ids[0],
      "No running instances found"
    ),
    NEW_NODEGROUP_2_SUBNET_ID     = aws_subnet.new_subnet.id,
    NEW_NODEGROUP_2_ROUTETABLE_ID = aws_route_table.new_route_table.id,
    DEFAULT_NODEGROUP_NATGATEWAY_ID = try(
      data.aws_nat_gateways.cluster_nat_gateways.ids[0],
      "No NAT Gateway found"
    ),

    # Nodegroup 3 variables
    NODE_NAME = try(
      format(
        "ip-%s.%s.compute.internal",
        replace(try(data.aws_instances.new_nodegroup_3_instances.private_ips[0], ""), ".", "-"),
        data.aws_region.current.name
      ),
      "No running instances found"
    ),
    INSTANCE_ID = try(
      data.aws_instances.new_nodegroup_3_instances.ids[0],
      "No instance ID found"
    ),
    AWS_REGION = data.aws_region.current.name
  }

  depends_on = [
    aws_eks_node_group.new_nodegroup_1,
    aws_eks_node_group.new_nodegroup_2,
    null_resource.wait_for_instance,
    data.aws_instances.new_nodegroup_2_instances,
    data.aws_instances.new_nodegroup_3_instances,
    data.aws_nat_gateways.cluster_nat_gateways,
    data.aws_autoscaling_group.new_nodegroup_1,
    data.aws_autoscaling_group.new_nodegroup_2,
    null_resource.increase_desired_count,
    null_resource.increase_nodegroup_2,
  ]
}
