output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    MY_ENVIRONMENT_VARIABLE = "abc1234",
    NODE_NAME = try(
      format(
        "ip-%s.us-west-2.compute.internal",
        replace(data.aws_instances.new_nodegroup_3_instances.private_ips[0], ".", "-")
      ),
      "No running instances found"
    ),
    INSTANCE_ID = try(
      data.aws_instances.new_nodegroup_3_instances.ids[0],
      "No instance ID found"
    )
  }

  depends_on = [
    data.aws_instances.new_nodegroup_3_instances
  ]
}
