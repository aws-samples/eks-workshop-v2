output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    AIML_SUBNETS        = "${data.aws_subnets.private.ids[0]},${data.aws_subnets.private.ids[1]},${data.aws_subnets.private.ids[2]}"
    KARPENTER_NODE_ROLE = module.eks_blueprints_addons.karpenter.node_iam_role_name
    KARPENTER_ARN       = module.eks_blueprints_addons.karpenter.node_iam_role_arn
    LBC_CHART_VERSION   = var.load_balancer_controller_chart_version
    LBC_ROLE_ARN        = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
  }
}
