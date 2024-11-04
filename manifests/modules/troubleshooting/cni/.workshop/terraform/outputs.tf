output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    # VPC_ID                                    = data.aws_vpc.selected.id,
    # LOAD_BALANCER_CONTROLLER_ROLE_NAME        = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_name,
    # LOAD_BALANCER_CONTROLLER_POLICY_ARN_FIX   = module.eks_blueprints_addons.aws_load_balancer_controller.iam_policy_arn,
    # LOAD_BALANCER_CONTROLLER_POLICY_ARN_ISSUE = aws_iam_policy.issue.arn,
    # LOAD_BALANCER_CONTROLLER_ROLE_ARN         = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
    VPC_CNI_IAM_ROLE_NAME = split("/", data.aws_eks_addon.vpc_cni.service_account_role_arn)[1],
    VPC_CNI_IAM_ROLE_ARN  = data.aws_eks_addon.vpc_cni.service_account_role_arn,
    ADDITIONAL_SUBNET_1 = aws_subnet.large_subnet[0].id,
    ADDITIONAL_SUBNET_2 = aws_subnet.large_subnet[1].id,
    ADDITIONAL_SUBNET_3 = aws_subnet.large_subnet[2].id,
    NODEGROUP_IAM_ROLE = aws_iam_role.node_role.arn,
    AWS_NODE_ADDON_CONFIG = jsonencode(data.aws_eks_addon.vpc_cni.configuration_values)
  }
}