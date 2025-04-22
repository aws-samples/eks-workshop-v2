output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = merge({
    VPC_ID                                    = data.aws_vpc.selected.id,
    LOAD_BALANCER_CONTROLLER_ROLE_NAME        = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_name,
    LOAD_BALANCER_CONTROLLER_POLICY_ARN_FIX   = module.eks_blueprints_addons.aws_load_balancer_controller.iam_policy_arn,
    LOAD_BALANCER_CONTROLLER_POLICY_ARN_ISSUE = aws_iam_policy.issue.arn,
    LOAD_BALANCER_CONTROLLER_ROLE_ARN         = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn,
    EKS_CLUSTER_NAME                          = var.addon_context.eks_cluster_id
    }, {
    for index, id in data.aws_subnets.public.ids : "PUBLIC_SUBNET_${index + 1}" => id
    }
  )
}


