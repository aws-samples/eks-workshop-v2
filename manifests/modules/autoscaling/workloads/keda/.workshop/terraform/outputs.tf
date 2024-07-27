output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    LBC_CHART_VERSION  = var.load_balancer_controller_chart_version
    LBC_ROLE_ARN       = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
    KEDA_ROLE_ARN      = module.iam_assumable_role_keda.iam_role_arn
    KEDA_CHART_VERSION = var.keda_chart_version
  }
}