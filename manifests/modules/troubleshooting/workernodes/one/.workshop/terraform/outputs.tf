output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    MY_ENVIRONMENT_VARIABLE  = "abc1234",
    NEW_NODEGROUP_1_ASG_NAME = aws_eks_node_group.new_nodegroup_1.resources[0].autoscaling_groups[0].name,
    NEW_NODEGROUP_1_LT_ID    = aws_eks_node_group.new_nodegroup_1.launch_template[0].id,
    NEW_KMS_KEY_ID           = aws_kms_key.new_kms_key.id
  }
}

# output "environment_variables" {
#   description = "Environment variables to be added to the IDE shell"
#   value = merge({
#     VPC_ID                                    = data.aws_vpc.selected.id,
#     LOAD_BALANCER_CONTROLLER_ROLE_NAME        = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_name,
#     LOAD_BALANCER_CONTROLLER_POLICY_ARN_FIX   = module.eks_blueprints_addons.aws_load_balancer_controller.iam_policy_arn,
#     LOAD_BALANCER_CONTROLLER_POLICY_ARN_ISSUE = aws_iam_policy.issue.arn,
#     LOAD_BALANCER_CONTROLLER_ROLE_ARN         = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
#     }, {
#     for index, id in data.aws_subnets.public.ids : "PUBLIC_SUBNET_${index + 1}" => id
#     }
#   )
# }
